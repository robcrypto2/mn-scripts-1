#!/bin/bash

set -e

export LC_ALL="en_US.UTF-8"

echo ""
echo "########################################################################"
echo "#   Welcome to the chain clean-up script for PACProtocol masternodes   #"
echo "########################################################################"
echo ""
echo "This script is to be ONLY used if the pacprotocol-mn.sh script was used to install the PAC masternode version 0.17.x or newer and the masternode is still installed!"
echo "Running this script on Ubuntu 20.04 LTS is highly recommended."
echo "Make sure you have enough memory and swap configured - their combined value should be at least 4 GB. Use the command 'free -h' to check the values (under 'Total')."
echo ""
if [ -e /root/.pacprotocol/pacprotocol.conf ]; then
            sleep 1
	else
	    read -p "No pacprotocol.conf in /root/.pacprotocol folder detected. Are you sure you want to continue [y/n]?" cont
	    if [ $cont = 'n' ] || [ $cont = 'no' ] || [ $cont = 'N' ] || [ $cont = 'No' ]; then
		exit
            fi
fi
sleep 10
echo "###################################"
echo "#  Updating the operating system  #"
echo "###################################"
echo ""
sleep 3
sudo apt-get -y update
sudo apt-get -y upgrade
echo ""
echo "Stopping the pac service"
set +e
~/PACProtocol/pacprotocol-cli stop
set -e
systemctl stop pac.service
echo "The pac service stopped"
echo ""
sleep 3
echo "########################################"
echo "#    Removing the current chain data   #"
echo "########################################"
echo ""
sleep 3
cd ~
rm -f .pacprotocol/banlist.dat
rm -f .pacprotocol/fee_estimates.dat
rm -f .pacprotocol/governance.dat
rm -f .pacprotocol/instantsend.dat
rm -f .pacprotocol/mempool.dat
rm -f .pacprotocol/mncache.dat
rm -f .pacprotocol/netfulfilled.dat
rm -f .pacprotocol/pacprotocol.pid
rm -f .pacprotocol/peers.dat
rm -f .pacprotocol/sporks.dat
rm -f .pacprotocol/*.log
rm -r -f .pacprotocol/blocks
rm -r -f .pacprotocol/chainstate/
rm -r -f .pacprotocol/database/
rm -r -f .pacprotocol/evodb/
rm -r -f .pacprotocol/llmq/
echo "Clean-up done!"
echo ""
#The five commands below should not be needed!
#cd ~/.pacprotocol
#set +e
#wget -q https://github.com/PACProtocolOfficial/mn-scripts/blob/master/peers.dat?raw=true
#mv peers.dat?raw=true peers.dat
#set -e
sleep 3
echo "Starting the pac service"
systemctl start pac.service
echo "The pac service started"
echo ""

echo "###############################"
echo "#      Running the wallet     #"
echo "###############################"
echo ""
echo "Please wait for 60 seconds!"
cd ~/PACProtocol
sleep 60

is_pac_running=`ps ax | grep -v grep | grep pacprotocold | wc -l`
if [ $is_pac_running -eq 0 ]; then
	echo ""
	echo "The daemon is not running or there is an issue, please restart the daemon!"
	echo "Please check PAC FAQ on the PAC Global website for further information or help!"
	echo ""
	exit
fi

echo ""
echo "Your masternode / hot wallet has started rebuilding the local copy of blockchain!"
echo ""
echo "Please execute following commands to check the status of your masternode:"
echo "~/PACProtocol/pacprotocol-cli -version"
echo "~/PACProtocol/pacprotocol-cli getblockcount"
echo "~/PACProtocol/pacprotocol-cli masternode status"
echo "~/PACProtocol/pacprotocol-cli mnsync status"
echo ""
