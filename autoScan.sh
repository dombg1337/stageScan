#!/bin/bash

function printHelp {
    printBanner
    echo "Usage:"
    echo "    --ip \"192.168.1.1\" | required"
    echo "    --vuln | if set, triggers nmap vuln scripts | optional"
    echo "    -e/--interface \"tun0\" | to specify network interface, default: eth0 | optional"
    echo "    -h/--help | display the help menu"
    
    exit 1
}

function printBanner {
	/usr/bin/base64 -d <<<"H4sIAAAAAAAAA5VSWxKDMAj8zyn4q85YuRAz60E4fGGJqY522oIPyC6LJIoAkG7vAIfVo+XqDV/u
Vppo5FaJh9OU6n6V1oTswh92WmnBRpCzX4g5OIbJ9nyubJBfSUcvZVPnCD2VgjNKBdR4kOacw7sD
NQalTSvfAnhwuKBo15QCSCe8jcg61nZVZ4W7TJhFLUU1Yud99AnYg3rOJ9iZE2vGnUixBR7PuJil
eL4KwGhu+56MCuiAg7j2wiW0736Gz2ZxNnFA+o2XDf7V/tGcY7cXH9i3IeACAAA=" | /usr/bin/gunzip
}

# check if no argument was supplied and print help

function printSeparator {
	printf "\n"
	/usr/bin/base64 -d <<<"H4sIAAAAAAAAA+NSiAcDSimuGgiDUoqLCwBNcUR3kgAAAA==" | /usr/bin/gunzip
	printf "\n"
}

if [ -z "$1" ]; then
    echo "No argument supplied"
    printHelp
    exit 1

fi

# set values to default
ip=""
vuln=""
interface="eth0"

# Load the user defined parameters
while [[ $# > 0 ]]
do
        case "$1" in

                --ip)
                        ip="$2"
                        shift #pop the first parameter in the series, making what used to be $2, now be $1.
                        ;;

                --vuln)
                        vuln=1
                        shift
                        ;;
		-e|--interface)
			interface="$2"
			shift
			;;

                --help|-h)
                        printHelp
			;;
        esac
        shift
done

# if ip was not supplied, print help menu and exit
if [ -z $ip ]; then
	echo "Please supply an IP to test"
	printHelp
fi

printBanner
printSeparator

# 1. prepare result directory

currentDate=`/usr/bin/date "+%Y%m%d-%H%M%S"`
resultDirectory="/tmp/scanResults_"$ip"_"$currentDate"/"
printf "Preparing output directory\n\n"
printf "Results are stored in /tmp folder: "$resultDirectory"\n"
mkdir $resultDirectory
printSeparator

# 2. run masscan on all ports with supplied ip and interface and print results

printf "Run masscan on all ports with on target(s) "$ip" using the interface "$interface"\n\n"
masscanOutputFile=$resultDirectory"masscanOutput"
printf "Command: /usr/bin/masscan -p1-65535,U:1-65535 $ip -e $interface --rate=1000 > $masscanOutputFile"

/usr/bin/masscan -p1-65535,U:1-65535 $ip -e $interface --rate=1000 > $masscanOutputFile

printf "Results of masscan\n\n"
/usr/bin/sudo bash -c "cat $masscanOutputFile"

printSeparator

# 3. filter found tcp and udp ports separately
# ---------------------------------cat masscan output-------- get 4th field ----only tcp------keep 0-9 only--------replace \n with ,-----remove last ,----
openTCPPorts=`/usr/bin/sudo /usr/bin/cat $masscanOutputFile | cut -d ' ' -f 4 | grep tcp |  sed 's/[^0-9]//g' | /usr/bin/tr '\n' ',' | sed 's/\(.*\),/\1/'`
openUDPPorts=`/usr/bin/sudo /usr/bin/cat $masscanOutputFile | cut -d ' ' -f 4 | grep udp |  sed 's/[^0-9]//g' | /usr/bin/tr '\n' ',' | sed 's/\(.*\),/\1/'`

openPorts="T:"$openTCPPorts",U:"$openUDPPorts # nmap format

# 4. run nmap service and version scan, display only open port results, save as all output formats
printf "Run nmap service and version scan on all found ports (tcp and udp)\n\n"
nmapServiceScanOutputFile=$resultDirectory"nmapServiceScan"
printf "Command: /usr/bin/sudo /usr/bin/nmap -p $openPorts -sSU -sC -sV -oA $nmapServiceScanOutputFile $ip --open\n\n"  

sleep 2
(/usr/bin/sudo /usr/bin/nmap -p $openPorts -sSU -sC -sV -oA $nmapServiceScanOutputFile $ip --open && printf "Scan successful")
printSeparator

# 5. run nmap vuln scan if --vuln was set

if [ vuln ]; then
	printf "Run nmap vuln scan on all found ports (tcp and udp)\n\n"
	nmapVulnScanOutputFile=$resultDirectory"nmapVulnScan"
	printf "Command: /usr/bin/sudo /usr/bin/nmap -p $openPorts -sSU --script="vuln" -oA $nmapVulnScanOUtputFile $ip --open\n\n" 	
	
	sleep 2
	(/usr/bin/sudo /usr/bin/nmap -p$openPorts -sSU --script="vuln" -oA $nmapVulnScanOUtputFile $ip --open && printf "Vuln Scan successful")
	printSeparator
fi


