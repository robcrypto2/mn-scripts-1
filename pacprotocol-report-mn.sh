set +e
export LC_ALL="en_US.UTF-8"

bd=$(tput bold)
nl=$(tput sgr0)
sync_status=""

echo ""
tput bold 
echo "############################################################"
echo "#   Welcome to the PACProtocol masternode report script!   #"
echo "############################################################"
echo ""
tput sgr0
sleep 3
curr_pacscan_expl="UNKNOWN"
curr_second_expl="UNKNOWN"
curr_block="UNKNOWN"
echo "${bd}What is the status of the pacg.service (if it exists)?${nl}"
systemctl status pac.service --no-pager --full
echo ""
echo "${bd}Is the pacprotocold process running?${nl}"
ps aux|grep pacprotocol|grep -v grep
is_pac_running=`ps ax | grep -v grep | grep pacprotocol | wc -l`
if [ $is_pac_running -eq 0 ]; then
	echo "${bd}The process is not running!${nl}"
fi
echo ""
echo "${bd}The current memory usage of the system is:${nl}"
free -h
echo ""
echo "${bd}The current disk usage of the system is:${nl}"
df|grep "^/dev/"
echo ""
echo "${bd}The masternode status (abbreviated) is:${nl}"
~/PACProtocol/pacprotocol-cli masternode status|grep '"PoSePenalty":'
~/PACProtocol/pacprotocol-cli masternode status|grep -A1 '"state":'
echo ""
echo "${bd}The masternode synchronisation status is:${nl}"
sync_status=$(~/PACProtocol/pacprotocol-cli mnsync status|grep -A6 '"AssetID":')
if [ "$sync_status" = "" ]; then
	echo ""
	echo "${bd}The masternode wallet is not running or not properly configured!${nl}"
	else
	~/PACProtocol/pacprotocol-cli mnsync status|grep -A6 '"AssetID":'
fi
echo ""
time=$(date)"; "$(uptime -p)
echo "${bd}The current (up)time is: ${nl}"$time
echo ""
curr_block=$(~/PACProtocol/pacprotocol-cli getblockcount)
curr_pacscan_expl=$(wget -T 3 -qO- https://pacscan.io/api/getblockcount)
curr_second_expl=$(wget -T 3 -qO- http://explorer.pacglobal.io/api/getblockcount)
echo "${bd}The current block this masternode is on: ${nl}"$curr_block
echo "${bd}The current block the PACscan explorer is on: ${nl}"$curr_pacscan_expl
echo "${bd}The current block the second explorer is on: ${nl}"$curr_second_expl
echo ""
wallet_version=$(~/PACProtocol/pacprotocol-cli -version)
echo "${bd}The masternode wallet version is: ${nl}"$wallet_version
echo ""
echo "${bd}The script has ended!${nl}"
echo ""

