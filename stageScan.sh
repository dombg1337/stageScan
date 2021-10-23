#!/bin/bash

function printHelp {
    printBanner
    echo "Usage:"
    echo "|    -ip/--ip 192.168.1.1           | set the target ip                                          | required"
    echo "|    -r/--rate 500                  | set the masscan packet/second rate, default: 1000          | optional"
    echo "|    -d/--directory /home/dombg/    | set the output directory (with trailing /), default /tmp/  | optional"
    echo "|    --vuln                         | if set, triggers nmap vuln scripts                         | optional"
    echo "|    -e/--interface tun0            | specify network interface, default: eth0                   | optional"
    echo "|    -h/--help                      | display the help menu"
    printf "\n\n"
    echo "Command to scan a list of IP's (supply each in a newline): cat ips | xargs -I % /bin/bash -c 'sudo ./stageScan.sh --ip %'"
    exit 1
}

function printBanner {
	/usr/bin/base64 -d <<<"H4sIAAAAAAAAA21Q0QrDMAh89yvubR20yfo/gqUM9jT2Nhj48fNM10KzM5x6KiYREIYeRnSqkDzsjJoTnS5NdQvPNT82xTJNJcMmpoNUsN8s/ALfGZrtWvcSLiFC1OjcMXDNxmxSNtYUmpgmbq0WZzQng8ycA1sYpby1S/cr9c/jT/9zILcd6fCey63MI9YP7q/n+rjKF6ccN5OBAQAA" | /usr/bin/gunzip
	
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
rate=1000
outputDirectory="/tmp/"
# Load the user defined parameters
while [[ $# > 0 ]]
do
        case "$1" in
                -ip|--ip)
                        ip="$2"
                        shift #pop the first parameter in the series, making what used to be $2, now be $1.
                        ;;
		-r|--rate)
                        rate="$2"
                        shift #pop the first parameter in the series, making what used to be $2, now be $1.
                        ;;
		-d|--directory)
                        outputDirectory="$2"
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
                -h|--help)
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

# 1. prepare directory to store results
if [[ "${outputDirectory: -1}" != "/" || ! -d "$outputDirectory" ]]; then
	printf "Error: \n\nDirectory $outputDirectory does not exist or has no trailing slash! Please use existing dir and supply the / at the end\n\n"
	exit 1
fi

currentDate=`/usr/bin/date "+%Y%m%d-%H%M%S"`
resultDirectory=$outputDirectory"stageScan_results_"$ip"_"$currentDate"/"
printf "Preparing output directory\n\n"
printf "Results are stored in /tmp folder: "$resultDirectory"\n"
mkdir $resultDirectory
printSeparator

# 2. run masscan on all ports with supplied ip and interface and print results

printf "Run masscan on all ports, target: "$ip" using the interface "$interface"\n\n"
masscanOutputFile=$resultDirectory"masscanOutput"
printf "Command: /usr/bin/sudo /usr/bin/masscan -p1-65535,U:1-65535 $ip -e $interface --rate=$rate > $masscanOutputFile\n\n"

/usr/bin/sudo /usr/bin/masscan -p1-65535,U:1-65535 $ip -e $interface --rate=$rate > $masscanOutputFile

printf "Results of masscan\n\n"
/usr/bin/sudo bash -c "cat $masscanOutputFile"
printSeparator

# 3. filter found tcp and udp ports separately

# ---------------------------------cat masscan output-------- get 4th field ----only tcp------keep 0-9 only--------replace \n with ,-----remove last ,----
openTCPPorts=`/usr/bin/sudo /usr/bin/cat $masscanOutputFile | cut -d ' ' -f 4 | grep tcp |  sed 's/[^0-9]//g' | /usr/bin/tr '\n' ',' | sed 's/\(.*\),/\1/'`
openUDPPorts=`/usr/bin/sudo /usr/bin/cat $masscanOutputFile | cut -d ' ' -f 4 | grep udp |  sed 's/[^0-9]//g' | /usr/bin/tr '\n' ',' | sed 's/\(.*\),/\1/'`
openPorts=""
if [ ! -z $openTCPPorts ]; then
	openPorts="T:"$openTCPPorts","
fi
if [ ! -z $openUDPPorts ]; then
	openPorts=$openPorts"U:"$openUDPPorts # nmap port specification f.e. "T:80,U:161" but "T:80," also works
fi
# check if open ports were detected
if [ -z $openPorts ]; then
	printf "No open ports (TCP/UDP) were detected by masscan on the target. Execution finished successfully."
	exit 0
fi

# 4. run nmap service and version scan, display only open port results, save as all output formats
printf "Run nmap service and version scan on all found ports (tcp and udp)\n\n"
nmapServiceScanOutputFile=$resultDirectory"nmapServiceScan"
printf "Command: /usr/bin/sudo /usr/bin/nmap -p $openPorts -sSU -sC -sV -oA $nmapServiceScanOutputFile $ip --open -vvv\n\n"  
sleep 2
(/usr/bin/sudo /usr/bin/nmap -p$openPorts -sSU -sC -sV -oA $nmapServiceScanOutputFile $ip --open -vvv && printf "Scan successful")
printSeparator

# 5. run nmap vuln scan if --vuln was set

if [ $vuln = 1 ]; then
	printf "Run nmap vuln scan on all found ports (tcp and udp)\n\n"
	nmapVulnScanOutputFile=$resultDirectory"nmapVulnScan"
	printf "Command: /usr/bin/sudo /usr/bin/nmap -p $openPorts -sSU --script="vuln" -oA $nmapVulnScanOUtputFile $ip --open -vvv\n\n" 	
	sleep 2
	(/usr/bin/sudo /usr/bin/nmap -p$openPorts -sSU --script="vuln" -oA $nmapVulnScanOUtputFile $ip --open -vvv && printf "Vuln Scan successful")
	printSeparator
fi

printf "Results are stored in: "$resultDirectory
