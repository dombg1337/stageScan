# stageScan (c) dombg

# Description

The script stages scans with masscan and nmap providing greater time efficiency (than nmap -p- scans) while still scanning all ports on the target.

## Execution

1. Masscan will scan all 65535 TCP and UDP ports
2. Nmap will perform safe scripts (-sC) and service+version (-sV) enumeration on the ports found by masscan.
3. Optionally runs nmap vuln scripts (--scripts="vuln") as an additional scan.

## Help

![image](https://user-images.githubusercontent.com/7427205/137182551-3795655b-4ac0-48ee-8133-1e33d1999671.png)

Mind: Please don't grant users permanent sudo rights to this script, easy PrivEsc via Command Injection since I don't sanitize any input.
