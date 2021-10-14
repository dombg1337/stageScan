# stageScan (c) dombg

## Why should I use stageScan?

The script stages scans with masscan and nmap providing greater time efficiency (than nmap -p- scans) while still scanning all ports on the target and leveraging nmap's powerful capabilities including NSE.

This is especially helpful in lab environments and/or CTF's (not recommended for stealthy red team assessments ;)). 

## Execution

1. Masscan will scan all 65535 TCP and UDP ports
2. Nmap will perform safe scripts (-sC) and service+version (-sV) enumeration on the ports found by masscan.
3. Optionally runs nmap vuln scripts (--scripts="vuln") as an additional scan.

## Help

![image](https://user-images.githubusercontent.com/7427205/137182551-3795655b-4ac0-48ee-8133-1e33d1999671.png)

List of IP's to check: stageScan does not currently support a list of IP's to test. 
To get around this issue, you can make use of the xargs command and supply a list of ips, each in a new line.
F.e.:

`cat ips | xargs -I % /bin/bash -c 'sudo ./stageScan.sh --ip %'`

Mind: Please don't grant users permanent sudo rights to this script, easy PrivEsc via Command Injection since I don't sanitize any input.
