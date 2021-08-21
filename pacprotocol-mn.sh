#!/bin/bash
set -e
export LC_ALL="en_US.UTF-8"
binary_url=$2
file_name=$1
extension=".tgz"
#Are the the needed paramters provided?
if [ "$binary_url" = "" ] || [ "$file_name" = "" ]; then
	echo ""
	echo "In order to run this script, you need to add two parameters: first one is the full file name of the wallet on the PAC Protocol Github, the second one is the full binary url leading to the file on the Github."
	echo "Please check PAC FAQ on the PAC website for further information or help!"
	echo ""
	exit
fi
#Is the daemon already running?
is_pac_running=`ps ax | grep -v grep | grep -e pacprotocold -e pacglobald | wc -l`
if [ $is_pac_running -eq 1 ]; then
	echo ""
	echo "A pacglobal/pacprotocol daemon is already running - this script is not to be used for upgrading!"
	echo "Please check PAC FAQ on the PAC Global website for further information or help!"
	echo ""
	exit
fi
echo ""
echo "###################################################"
echo "#   Welcome to the pacprotocol masternode setup   #"
echo "###################################################"
echo ""
echo "Running this script as root on Ubuntu 20.04 LTS is highly recommended."
echo "Please note that this script will try to configure 3 GB of swap - the combined value of memory and swap should be at least 4 GB. Use the command 'free -h' to check the values (under 'Total')." 
echo ""
sleep 10
#ipaddr="$(dig +short myip.opendns.com @resolver1.opendns.com)"
ipaddr="$(wget -qO- ifconfig.me)"
while [[ $ipaddr = '' ]] || [[ $ipaddr = ' ' ]]; do
	read -p 'Unable to find an external IP, please provide one: ' ipaddr
	sleep 2
done
read -p 'Please provide masternodeblsprivkey: ' mnkey
while [[ $mnkey = '' ]] || [[ $mnkey = ' ' ]]; do
	read -p 'You did not provide a masternodeblsprivkey, please provide one: ' mnkey
	sleep 2
done
echo ""
echo "###########################################################################"
echo "#  Installing dependencies / setting the operating system to auto-update  #"
echo "###########################################################################"
echo ""
sleep 3
set +
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install git python3 virtualenv
sudo apt-get -y install unattended-upgrades
sudo apt-get -y install ufw pwgen
set -
#cat /etc/apt/apt.conf.d/50unattended-upgrades | grep -v "Unattended-Upgrade::Automatic-Reboot \"false\"" > /etc/apt/apt.conf.d/50unattended-upgrades2 && mv /etc/apt/apt.conf.d/50unattended-upgrades2 /etc/apt/apt.conf.d/50unattended-upgrades
#cat /etc/apt/apt.conf.d/50unattended-upgrades | grep -v "Unattended-Upgrade::Remove-Unused-Dependencies \"false\"" > /etc/apt/apt.conf.d/50unattended-upgrades2 && mv /etc/apt/apt.conf.d/50unattended-upgrades2 /etc/apt/apt.conf.d/50unattended-upgrades
#echo "Unattended-Upgrade::Remove-Unused-Dependencies \"true\";" >> /etc/apt/apt.conf.d/50unattended-upgrades
#echo "Unattended-Upgrade::Automatic-Reboot \"true\";" >> /etc/apt/apt.conf.d/50unattended-upgrades
#echo "\"\${distro_id}:\${distro_codename}-updates\";" >> /etc/apt/apt.conf.d/50unattended-upgrades
#echo "Unattended-Upgrade::Remove-Unused-Kernel-Packages \"true\";" >>  /etc/apt/apt.conf.d/50unattended-upgrades
#echo "Unattended-Upgrade::Automatic-Reboot-Time \"02:00\";" >> /etc/apt/apt.conf.d/50unattended-upgrades

sed -i 's#//\t"${distro_id}:${distro_codename}-updates"#\t"${distro_id}:${distro_codename}-updates"#' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's#//Unattended-Upgrade::Remove-Unused-Dependencies "false"#Unattended-Upgrade::Remove-Unused-Dependencies "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
#sed -i 's#//Unattended-Upgrade::Automatic-Reboot "false"#Unattended-Upgrade::Automatic-Reboot "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's#//Unattended-Upgrade::Remove-Unused-Kernel-Packages "true"#Unattended-Upgrade::Remove-Unused-Kernel-Packages "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
#sed -i 's#//Unattended-Upgrade::Automatic-Reboot-Time "02:00"#Unattended-Upgrade::Automatic-Reboot-Time "02:00"#' /etc/apt/apt.conf.d/50unattended-upgrades

cat <<EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "2";
EOF
echo ""
echo "###############################"
echo "#   Setting up the firewall   #"
echo "###############################"
echo ""
sleep 2
sudo ufw status
sudo ufw disable
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw allow 7112/tcp
sudo ufw logging on
sudo ufw --force enable
sudo ufw status
sudo iptables -A INPUT -p tcp --dport 7112 -j ACCEPT
echo ""
echo "Proceed with the setup of the swap file [y/n]?"
echo "(Defaults to 'y' in 5 seconds)"
set +e
read -t 5 cont
set -e
if [ "$cont" = "" ]; then
        cont=Y
fi
if [ $cont = 'y' ] || [ $cont = 'yes' ] || [ $cont = 'Y' ] || [ $cont = 'Yes' ]; then
		echo ""
		echo "###########################"
		echo "#   Setting up swapfile   #"
		echo "###########################"
		echo ""
		sudo swapoff -a
		sudo fallocate -l 100M /swapfile
		sudo chmod 600 /swapfile
		sudo mkswap /swapfile
		sudo swapon /swapfile
		echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
		sleep 2
    else
        echo ""
		echo "Warning: Swap was not setup as desired. Use free -h command to check how much memory / swap is available."
		sleep 5
fi
echo ""
echo "###############################"
echo "#      Get/Setup binaries     #"
echo "###############################"
echo ""
sleep 3
cd ~
set +e
wget $binary_url
set -e
if test -e "$file_name$extension"; then
echo "Unpacking pacprotocol distribution"
systemctl stop pac.service || true
	tar -xzvf $file_name$extension
	rm -r $file_name$extension
	rm -r -f PACProtocol
	mv -v $file_name PACProtocol
	cd PACProtocol
	chmod +x pacprotocold
	chmod +x pacprotocol-cli
	echo "Binaries were saved to: /root/PACProtocol"
	echo ""
else
	echo ""
	echo "There was a problem downloading the binaries, please try running the script again."
	echo "Most likely are the parameters used to run the script wrong."
	echo "Please check PAC FAQ on the PAC website for further information or help!"
	echo ""
	exit -1
fi
echo "#################################"
echo "#     Configuring the wallet    #"
echo "#################################"
echo ""
echo "A .pacprotocol folder will be created, unless it already exists."
sleep 3
if [ -d ~/.pacprotocol ]; then
	if [ -e ~/.pacprotocol/pacprotocol.conf ]; then
	read -p "The file pacprotocol.conf already exists and will be replaced. Do you agree [y/n]?" cont
		if [ $cont = 'y' ] || [ $cont = 'yes' ] || [ $cont = 'Y' ] || [ $cont = 'Yes' ]; then
			sudo rm ~/.pacprotocol/pacprotocol.conf
			touch ~/.pacprotocol/pacprotocol.conf
			cd ~/.pacprotocol
		fi
	fi
else
	echo "Creating .pacprotocol dir"
	mkdir -p ~/.pacprotocol
	cd ~/.pacprotocol
	touch pacprotocol.conf
fi
#The four commands below should not be needed!
#set +e
#wget -q https://github.com/pacprotocolOfficial/mn-scripts/blob/master/peers.dat?raw=true
#mv peers.dat?raw=true peers.dat
#set -e

echo "Configuring the pacprotocol.conf"
echo "#----" > pacprotocol.conf
echo "rpcuser=$(pwgen -s 16 1)" >> pacprotocol.conf
echo "rpcpassword=$(pwgen -s 64 1)" >> pacprotocol.conf
echo "rpcallowip=127.0.0.1" >> pacprotocol.conf
echo "rpcport=7111" >> pacprotocol.conf
echo "#----" >> pacprotocol.conf
echo "listen=1" >> pacprotocol.conf
echo "server=1" >> pacprotocol.conf
echo "daemon=1" >> pacprotocol.conf
echo "maxconnections=125" >> pacprotocol.conf
echo "#----" >> pacprotocol.conf
#echo "masternode=1" >> pacprotocol.conf
echo "masternodeblsprivkey=$mnkey" >> pacprotocol.conf
echo "externalip=$ipaddr" >> pacprotocol.conf
echo "#----" >> pacprotocol.conf
echo ""
echo "#######################################"
echo "#      Creating systemctl service     #"
echo "#######################################"
echo ""
cat <<EOF > /etc/systemd/system/pac.service
[Unit]
Description=PAC Protocol daemon
After=network.target
[Service]
User=root
Group=root
Type=forking
PIDFile=/root/.pacprotocol/pacprotocol.pid
ExecStart=/root/PACProtocol/pacprotocold -daemon -pid=/root/.pacprotocol/pacprotocol.pid -conf=/root/.pacprotocol/pacprotocol.conf -datadir=/root/.pacprotocol/
ExecStop=-/root/PACProtocol/pacprotocol-cli -conf=/root/.pacprotocol/pacprotocol.conf -datadir=/root/.pacprotocol/ stop
Restart=always
RestartSec=20s
PrivateTmp=true
TimeoutStopSec=7200s
TimeoutStartSec=30s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
#enable the service
systemctl enable pac.service
echo "pac.service enabled"
#start the service
systemctl start pac.service
echo "pac.service started"
echo ""
echo "#################################"
echo "#      Installing sentinel      #"
echo "#################################"
echo ""
cd ~
set +e
#install python if missing, install pyhton 2.x virtualenv
#apt-get -y install python python-virtualenv 
#install python3 and coresponding virtualenv
#apt-get -y install git python3 virtualenv => done above
#apt-get -y install virtualenv git
#git clone https://github.com/PACGlobalOfficial/sentinel.git
git clone https://github.com/pacprotocol/sentinel.git
set -e
cd sentinel
#virtualenv ./venv
virtualenv -p $(which python3) ./venv
./venv/bin/pip install -r requirements.txt
cat /etc/crontab | grep -v "* * * * * root cd ~/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" > /etc/crontab2 && mv /etc/crontab2 /etc/crontab
echo "* * * * * root cd ~/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> /etc/crontab
#cat <<EOF > /etc/cron.d/per_minute
#* * * * * root cd ~/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1
#EOF
echo ""
echo "###############################"
echo "#      Running the wallet     #"
echo "###############################"
echo ""
echo "Please wait for 60 seconds!"
echo ""
sleep 60
is_pac_running=`ps ax | grep -v grep | grep pacprotocold | wc -l`
if [ $is_pac_running -eq 0 ]; then
	echo "The daemon is not running or there is an issue, please restart the daemon!"
	echo "Please check PAC FAQ on the PAC Global website for further information or help!"
	echo ""
	exit
fi
~/PACProtocol/pacprotocol-cli mnsync status
echo ""
echo "Your masternode wallet on the server has been setup and will be ready when the synchronization is done!"
echo ""
echo "Please execute following commands to check the status of your masternode:"
echo "~/PACProtocol/pacprotocol-cli -version"
echo "~/PACProtocol/pacprotocol-cli getblockcount"
echo "~/PACProtocol/pacprotocol-cli masternode status"
echo "~/PACProtocol/pacprotocol-cli mnsync status"
echo ""
