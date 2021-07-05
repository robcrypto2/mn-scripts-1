#!/bin/bash
set -e
export LC_ALL="en_US.UTF-8"
binary_url=$2
file_name=$1
extension=".tgz"
#Are the the needed parameters provided?
if [ "$binary_url" = "" ] || [ "$file_name" = "" ]; then
	echo ""
	echo "In order to run this script, you need to add two parameters: first one is the full file name of the wallet on the PAC Protocol Github, the second one is the full binary url leading to the file on the Github."
	echo "Please check PAC FAQ on the website for further information or help!"
	echo ""
	exit
fi
echo ""
echo "###########################################################################"
echo "#   Welcome to the PACProtocol upgrade script for PACGlobal masternodes   #"
echo "###########################################################################"
echo ""
echo "This script is to be ONLY used if the pacglobal-mn.sh script was used to install the PAC masternode version 0.15.1 or 0.15.2 and the masternode is still installed!"
echo "Running this script on Ubuntu 18.04 LTS or Ubuntu 20.04 LTS version is highly recommended."
echo "Make sure you have enough memory and swap configured - their combined value should be at least 4 GB. Use the command 'free -h' to check the values (under 'Total')."
if [ -e /root/PACGlobal/pacglobald ]; then
            sleep 1
	else
	    echo ""
		read -p "No files in /root/PACGlobal detected. Are you sure you want to continue [y/n]?" cont
	    if [ $cont = 'n' ] || [ $cont = 'no' ] || [ $cont = 'N' ] || [ $cont = 'No' ]; then
		exit
            fi
fi
sleep 10
echo ""
echo "#################################################"
echo "#  Setting the operating system to auto-update  #"
echo "#################################################"
echo ""
sleep 3
set +
apt-get -y update
apt-get -y install unattended-upgrades
apt-get -y install git python3 virtualenv
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
#echo ""
#echo ""
#echo "###################################"
#echo "#  Updating the operating system  #"
#echo "###################################"
#echo ""
#sleep 3
#sudo apt-get -y update
#sudo apt-get -y upgrade
echo ""
echo "#################################"
echo "#      Installing sentinel      #"
echo "#################################"
echo ""
cd ~
cat /etc/crontab | grep -v "* * * * * root cd ~/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" > /etc/crontab2 && mv /etc/crontab2 /etc/crontab
rm -r -f ~/sentinel
set +e
#apt-get -y install git python3 virtualenv => done above!
#apt-get -y install python python-virtualenv 
#apt-get -y install virtualenv git
#git clone https://github.com/PACGlobalOfficial/sentinel.git 
git clone https://github.com/pacprotocol/sentinel.git
set -e
cd sentinel
#virtualenv ./venv
virtualenv -p $(which python3) ./venv
./venv/bin/pip install -r requirements.txt
echo "* * * * * root cd ~/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> /etc/crontab
#cat <<EOF > /etc/cron.d/per_minute
#* * * * * root cd ~/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1
#EOF
echo ""
echo "Stopping the pacg service"
set +e
~/PACGlobal/pacglobal-cli stop
set -e
systemctl stop pacg.service || true
echo "The pacg service stopped"
sleep 3
echo ""
echo "#########################################"
echo "#      Getting/Setting binaries up      #"
echo "#########################################"
echo ""
sleep 3
cd ~
set +e
wget $binary_url
set -e
if test -e "$file_name$extension"; then
		echo ""
		echo "Unpacking PACProtocol distribution"
		sleep 3
		rm -r -f PACGlobal
		rm -r -f PACProtocol
		tar -xzvf $file_name$extension
		rm -r $file_name$extension
		mv -v $file_name PACProtocol
		cd PACProtocol
		chmod +x pacprotocold
		chmod +x pacprotocol-cli
		echo "Binaries were saved to: /root/PACProtocol"
	else
		echo ""
		echo "There was a problem downloading the binaries, please try running the script again."
		echo "Most likely are the parameters used to run the script wrong."
		echo "Please check PAC FAQ on the PAC Global website for further information or help!"
		echo ""
		exit -1
fi
cd ~
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
		sudo rm -r /swapfile
		sudo fallocate -l 3G /swapfile
		sudo chmod 600 /swapfile
		sudo mkswap /swapfile
		sudo swapon /swapfile
		#echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
		sleep 2
    else
        echo ""
		echo "Warning: Swap setup was not changed as desired. Use free -h command to check how much memory / swap is available."
		sleep 5
fi
echo ""
echo "######################################################################"
echo "#    Modifying the config files and folders. Remaking the service    #"
echo "######################################################################"
echo ""
mv -v ~/.PACGlobal ~/.pacprotocol
mv -v ~/.pacprotocol/pacglobal.conf ~/.pacprotocol/pacprotocol.conf
cat ~/.pacprotocol/pacprotocol.conf | grep -v "maxconnections=64" > ~/.pacprotocol/pacprotocol.conf2 && mv ~/.pacprotocol/pacprotocol.conf2 ~/.pacprotocol/pacprotocol.conf
echo "maxconnections=125" >> ~/.pacprotocol/pacprotocol.conf
systemctl disable pacg.service
rm -r -f /etc/systemd/system/pacg.service
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
echo "###############################"
echo "#      Running the wallet     #"
echo "###############################"
echo ""
echo "Please wait for 60 seconds!"
echo ""
cd ~/PACProtocol
sleep 60

is_pac_running=`ps ax | grep -v grep | grep pacprotocold | wc -l`
if [ $is_pac_running -eq 0 ]; then
	echo ""
	echo "The daemon is not running or there is an issue, please restart the daemon!"
	echo "Please check PAC FAQ on the PAC Protocol website for further information or help!"
	echo ""
	exit
fi

echo ""
echo "Your masternode / hot wallet binaries have been upgraded!"
echo ""
echo "Please execute following commands to check the status of your masternode:"
echo "~/PACProtocol/pacprotocol-cli -version"
echo "~/PACProtocol/pacprotocol-cli getblockcount"
echo "~/PACProtocol/pacprotocol-cli masternode status"
echo "~/PACProtocol/pacprotocol-cli mnsync status"
echo ""


