#!/bin/bash
#/bin/anonymous
#code-name: Friday the 13th
clear

#====================C O L O R S====================

RED='\033[1;31m'
NC='\033[0m'


printf "${RED}   ###    ##    ##  #######  ##    ## ##    ## ##     ##  #######  ##     ##  ###### \n"
printf "  ## ##   ###   ## ##     ## ###   ##  ##  ##  ###   ### ##     ## ##     ## ##    ##\n"
printf " ##   ##  ####  ## ##     ## ####  ##   ####   #### #### ##     ## ##     ## ##      \n"
printf "##     ## ## ## ## ##     ## ## ## ##    ##    ## ### ## ##     ## ##     ##  ###### \n"
printf "######### ##  #### ##     ## ##  ####    ##    ##     ## ##     ## ##     ##       ##\n"
printf "##     ## ##   ### ##     ## ##   ###    ##    ##     ## ##     ## ##     ## ##    ##\n"
printf "##     ## ##    ##  #######  ##    ##    ##    ##     ##  #######   #######   ###### ${NC}\n"


#====================R O O T   O N L Y====================

if [ $EUID -ne 0 ]; then
	printf "\n\n${RED}Please run script as root !!!${NC}\n\n"
	exit 1
fi


#====================S E T T I N G S====================

NON_TOR="192.168.0.0/16 172.16.0.0/12"
TOR_UID="debian-tor"
TRANS_PORT="9040"
TO_KILL="chrome midor iceweasel megasync firefox pidgin skype thunderbird noip2 qbittorrent remmina"  # separate by space
BLEACHBIT_CLEANERS="bash.history system.cache system.clipboard system.custom system.recent_documents system.rotated_logs system.tmp system.trash"  # separate by space
REAL_HOSTNAME="terminal"
NAMESERVER="127.0.0.1"
RESOLV_CONF="/etc/resolv.conf"
INTERFACES="eth0 wlan0" # separate by space
CHECK_URL="https://check.torproject.org/?lang=en_US"
TEMP_FILE="/tmp/tor_check.tmp"
ICON="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/anonymous.png"

check_apps() {
	printf "\n${RED}CHECK REQUIRED APPS: ${NC}"

	if command -v tor >/dev/null ; then
		printf "\ntor: [OK]"
		if command -v macchanger >/dev/null ; then
			printf "\nmacchanger: [OK]"
			if command -v resolvconf >/dev/null ; then
				printf "\nresolvconf: [OK]"
				if command -v bleachbit >/dev/null ; then
					printf "\nbleachbit: [OK]"
					if command -v notify-send >/dev/null ;then
						printf "\nnotify-send: [OK]\n"
						check_configs
					else
						printf "\nnotify-send: is ${RED}not installed!${NC} Install it now? (y/n) "
						read answer
						if printf "$answer" | grep -iq "^y" ;then
							apt-get install libnotify-bin -y
							check_apps
						else
							clear
							exit 1
						fi
					fi
				else
					printf "\nbleachbit: is ${RED}not installed!${NC} Install it now? (y/n) "
					read answer
					if printf "$answer" | grep -iq "^y" ;then
						apt-get install bleachbit -y
						check_apps
					else
						clear
						exit 1
					fi
				fi
			else
				printf "\nresolvconf: is ${RED}not installed!${NC} Install it now? (y/n) "
				read answer
				if printf "$answer" | grep -iq "^y" ;then
					apt-get install resolvconf -y
					check_apps
				else
					clear
					exit 1
				fi
			fi
		else
			printf "\nmacchanger is ${RED}not installed!${NC} Install it now? (y/n) "
			read answer
			if printf "$answer" | grep -iq "^y" ;then
				apt-get install macchanger -y
				check_apps
			else
				clear
				exit 1
			fi
		fi
	else
		printf "\ntor is ${RED}not installed${NC}! Install it now? (y/n) "
		read answer
		if printf "$answer" | grep -iq "^y" ;then
			apt-get install tor -y
			check_apps
		else
			clear
			exit 1
		fi

	fi
}


#====================C H E C K  C O N F I G====================

check_configs() {
	printf "\n${RED}CHECK CONFIG: ${NC}"

	grep -q -x 'RUN_DAEMON="yes"' /etc/default/tor
	if [ $? -ne 0 ]; then
		printf "\n${RED}[!] Please add the following to your '/etc/default/tor' and restart the service:${NC}"
		printf '\nRUN_DAEMON="yes"'

		read -p "Do you want to edit file now? (y/n)" -n 1 -r

		if [[ $REPLY =~ ^[Yy]$ ]]; then
			nano /etc/default/tor
			clear
			check_configs
		else
			clear
			exit 1

		fi
	fi
	printf '\nRUN_DAEMON="yes" [OK]\n'

	grep -q -x 'VirtualAddrNetwork 10.192.0.0/10' /etc/tor/torrc
	VAR1=$?

	grep -q -x 'TransPort 9040' /etc/tor/torrc
	VAR2=$?

	grep -q -x 'DNSPort 53' /etc/tor/torrc
	VAR3=$?

	grep -q -x 'AutomapHostsOnResolve 1' /etc/tor/torrc
	VAR4=$?

	while [ $VAR1 -ne 0 ] || [ $VAR2 -ne 0 ] || [ $VAR3 -ne 0 ] || [ $VAR4 -ne 0 ]; do
		printf "\n${RED}[!] Please add the following to your '/etc/tor/torrc' and restart service:${NC}"
		printf '\nVirtualAddrNetwork 10.192.0.0/10'
		printf '\nTransPort 9040'
		printf '\nDNSPort 53'
		printf '\nAutomapHostsOnResolve 1\n\n'


		read -p "Do you want to edit file now? (y/n)" -n 1 -r

		if [[ $REPLY =~ ^[Yy]$ ]]; then
			nano /etc/tor/torrc
			clear
			check_configs
		else
			clear
			exit 1
		fi
	done
	printf "\nVirtualAddrNetwork 10.192.0.0/10 [OK]"
	printf "\nTransPort 9040 [OK]"
	printf "\nDNSPort 53 [OK]"
	printf "\nAutomapHostsOnResolve 1 [OK]\n"



}


#====================ANONYMOUS START====================

do_start() {
	check_apps

	printf "\n${RED}STOP NETWORK MANAGER: ${NC}"
	killer network-manager 0

	printf "\n${RED}KILL APPLICATIONS: ${NC}"
	kill_processes

	printf "\n${RED}STOP TOR: ${NC}"
	killer tor 0

	printf "\n${RED}STOP RESOLVCONF: ${NC}"
	killer resolvconf 0

	printf "\n${RED}CHANGE MAC ADDRESS: ${NC}"
	change_mac

	#printf "\n${RED}CHANGE HOSTNAME: ${NC}"
	#change_hostname

	printf "\n${RED}START TOR: ${NC}"
	killer tor 1

	printf "\n${RED}REDIRECT TRAFFIC TO TOR: ${NC}\n"
	redirect_to_tor

	printf "\n${RED}START NETWORK MANAGER: ${NC}"
	killer network-manager 1

	printf "\n${RED}CONNECTING TO TOR NETWORK: ${NC} please wait "
	do_status
}


#====================ANONYMOUS STOP====================

do_stop() {
	printf "\n${RED}STOP NETWORK MANAGER: ${NC}"
	killer network-manager 0

	printf "\n${RED}KILL APPLICATIONS: ${NC}"
	kill_processes

	printf "\n${RED}STOP TOR: ${NC}"
	killer tor 0

	printf "\n${RED}FLUSH IPTABLES: ${NC}\n"
	iptables_flush

	printf "restore saved iptables: "
	restore_iptables

	printf "\n${RED}CHANGE MAC ADDRESS: ${NC}"
	change_mac

	#printf "\n\n${RED}RESTORE ORIGINAL HOSTNAME: ${NC}\n"
	#change_hostname $REAL_HOSTNAME

	printf "\n${RED}WIPE HISTORY: ${NC}"
	bleachbit -c $BLEACHBIT_CLEANERS >/dev/null
	printf "[OK]\n"

	printf "\n${RED}START RESOLVCONF: ${NC}"
	killer resolvconf 1

	printf "\n${RED}START NETWORK MANAGER: ${NC}"
	killer network-manager 1

	printf "\n${RED}RESTORING ORIGINAL IDENTITY ${NC}"
	do_status
}


#====================ANONYMOUS STATUS====================

do_status() {
	until $(curl --output $TEMP_FILE --silent --fail $CHECK_URL); do
		printf '.'
		sleep 1s
	done
	printf "[OK]"

	IP=$(egrep -m1 -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$TEMP_FILE")
	RESULT="Congratulations. This browser is configured to use Tor."

	if grep -q "$RESULT" "$TEMP_FILE"; then
		printf "\nAnonymous: [ON]"
		printf "\nPublic IP: $IP\n"
		notify-send -i $ICON -u critical "$(echo -e "Anonymous ON\nPublic IP: $IP")"
	else
		printf "\nAnonymous: [OFF]"
		printf "\nPublic IP: $IP\n"
		notify-send -i $ICON -u critical "$(echo -e "Anonymous OFF\nPublic IP: $IP")"
	fi

	rm $TEMP_FILE
	printf "\n"
}


#==================== K I L L E R ====================

killer() {

	DISTRO=$(lsb_release -si)

	if [[ $DISTRO == "Ubuntu" ]] ; then
		STAT1="start/running"
		STAT2="stop/waiting"
		COMM=$(service $1 status | grep "$STAT1" | grep -v "$STAT2" | wc -l)
	elif [[ $DISTRO == "Kali" ]] ; then
		STAT1="active"
		STAT2="dead"
		COMM=$(service $1 status | grep $STAT1 | grep $STAT2 )
	fi

	#STATE=$(service $1 status | grep "$STAT1" | grep -v "$STAT2" | wc -l)
	#STATE=$(service $1 status | grep $STAT1 | grep $STAT2 )
	RET=$COMM
	RET=$?
	if [[ $2 != $RET ]] ;	then
		while [[ $2 != $RET ]] ; do
			if [[ $2 != 1 ]]; then
				printf "trying to stop $1 ... "
				service $1 stop > /dev/null 2>&1
				sleep 1s
				STATE=$(service $1 status | grep $STAT1 | grep $STAT2 )
				RET=$?
				#echo "ret je sada $RET"
				#echo "stanje servisa $STATE"
			else
				printf "trying to start $1 ... "
				service $1 start > /dev/null 2>&1
				sleep 1s
				STATE=$(service $1 status | grep $STAT1 | grep $STAT2 )
				RET=$?
				#echo "ret je sada $RET"
				#echo "stanje servisa $STATE"
			fi
		done
		printf "[OK]\n"
	else
		printf "[OK]\n"
	fi
}


#====================REDIRECT TO TOR====================

redirect_to_tor() {
	if [ ! -e /var/run/tor/tor.pid ]; then
		printf "${RED} Tor is not running! Quitting... ${NC}\n"
		exit 1
	fi

	if ! [ -f /etc/network/iptables.rules ]; then
		iptables-save > /etc/network/iptables.rules
	fi

	iptables_flush

	check_nameserver

	iptables -t nat -A OUTPUT -m owner --uid-owner $TOR_UID -j RETURN
	iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53

	for NET in $NON_TOR 127.0.0.0/9 127.128.0.0/10; do
		iptables -t nat -A OUTPUT -d "$NET" -j RETURN
	done

	iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports $TRANS_PORT
	iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

	for NET in $NON_TOR 127.0.0.0/8; do
		iptables -A OUTPUT -d "$NET" -j ACCEPT
	done

	iptables -A OUTPUT -m owner --uid-owner $TOR_UID -j ACCEPT
	iptables -A OUTPUT -j REJECT

	printf "new $(iptables_check)"

	printf "\nRouting comleted [OK]\n"
}


#====================RESTORE IPTABLES====================

restore_iptables() {
	if [ -f /etc/network/iptables.rules ]; then
		iptables-restore < /etc/network/iptables.rules
		rm /etc/network/iptables.rules
		printf "[OK]\n"
	else
		printf "nothing to restore [OK]\n"
	fi

}

#====================FLUSH IPTABLES====================

iptables_flush() {
	iptables -F
	iptables -t nat -F
	iptables_check
}


#====================CHECK IPTABLES====================

iptables_check() {
	printf "iptables rules: ${NC}"
	RULES=$(sudo iptables -n -L -v --line-numbers | egrep "^[0-9]" | wc -l)
	printf "$RULES [OK]\n"
}


#====================CHECK NAMESERVER====================

check_nameserver() {
	echo "nameserver $NAMESERVER" > $RESOLV_CONF
	resolv_address=$(cat $RESOLV_CONF | cut -d " " -f 2)

	if [[ $resolv_address != $NAMESERVER ]] ; then
		printf "\n${RED}Nameserver config ERROR. Exiting ... ${NC}\n"
		exit 1
	else
		printf "nameserver: $resolv_address [OK]\n"
	fi
}


#====================CHANGE HOSTNAME====================

change_hostname() {
	dhclient -r
	rm -f /var/lib/dhcp/dhclient*

	RANDOM_HOSTNAME=$(shuf -n 1 /etc/dictionaries-common/words | sed -r 's/[^a-zA-Z]//g' | awk '{print tolower($0)}')
	NEW_HOSTNAME=${1:-$RANDOM_HOSTNAME}

	echo "$NEW_HOSTNAME" > /etc/hostname
	sed -i 's/127.0.1.1.*/127.0.1.1\t'"$NEW_HOSTNAME"'/g' /etc/hosts

	printf "\n${RED}[*] STOP HOSTNAME: ${NC}"
	killer hostname 0

	CURRENT_HOSTNAME=$(hostname)

	avahi-daemon --kill
}


#====================CHANGE MAC ADDRESS====================

change_mac() {
	for device in $INTERFACES; do
		read MAC </sys/class/net/$device/address


		printf "\n$device new MAC address: $MAC [OK]"
		#printf "   $(macchanger -A $device)\n"
	done
	printf "\n"
}


#====================KILL PROCESSES====================

kill_processes() {
	for KILLPID in $TO_KILL ; do
		if pgrep $KILLPID >/dev/null 2>&1 ; then
			printf "\n$KILLPID: ${RED}Alive!${NC} Trying to kill ..."
			pkill -9 $KILLPID
			printf "[OK]"
		else
			printf "\n$KILLPID: Already Dead [OK]"
		fi
	done
	printf "\n"

}


#====================P L A Y G R O U N D====================

do_test() {
	printf "Is this a good question (y/n)? "
	read answer
	if printf "$answer" | grep -iq "^y" ;then
		echo Yes
	else
		echo No
	fi


}

#====================ANONYMOUS COMMANDS====================
case "$1" in
	start)
		do_start
	;;
	stop)
		do_stop
	;;
	status)
		do_status
	;;
	test_me)
		do_test
	;;
	*)
		echo "Usage: $0 {start|stop|status}" >&2
		exit 3
	;;
esac

exit 0
