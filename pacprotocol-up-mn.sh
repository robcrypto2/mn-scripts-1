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
echo "#   Welcome to the PACProtocol upgrade script                             #"
echo "###########################################################################"
echo ""
echo "This script is to be ONLY used for PAC Protocol masternodes version 0.17.0.3 or higher and the masternode is still installed!"
echo "Running this script on Ubuntu 18.04 LTS or Ubuntu 20.04 LTS version is highly recommended."
echo "Make sure you have enough memory and swap configured - their combined value should be at least 4 GB. Use the command 'free -h' to check the values (under 'Total')."

# bypass previous setup

echo ""
echo "Stopping the pac protocol service"
set +e
~/PACProtocol/pacprotocol-cli stop
set -e
systemctl stop pac.service || true
echo "The pac service stopped"
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

#reindex
echo "####################################"
echo "#      Resetting Blockchain data    #"
echo "####################################"
cd
~/PACProtocol/pacprotocold -reindex
echo "waiting 30 seconds"
sleep 30
~/PACProtocol/pacprotocol-cli stop
sleep 10

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
echo "Please wait for 10 seconds!"
echo ""
cd ~/PACProtocol
sleep 10

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
