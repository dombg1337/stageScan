# stageScan (c) dombg

## Description

The script stages scans with masscan and nmap providing greater time efficiency (than nmap -p- scans) while still scanning all ports on the target and leveraging nmap's powerful capabilities including NSE.

This is especially helpful in lab environments and/or CTF's (not recommended for stealthy red team assessments ;)). 

## Execution

1. Masscan will scan all `65535 TCP` and `UDP` ports
2. Nmap will perform safe scripts (`-sC`) and service+version (`-sV`) enumeration on the ports found by masscan.
3. Optionally runs nmap vuln scripts (`--scripts="vuln"`) as an additional scan.
4. Optionally runs nmap UDP scans on `--top-ports`. See usage examples for why this might be beneficial.

## Help

![image](https://user-images.githubusercontent.com/7427205/139715948-b2688ab2-0ea1-47d6-9588-4454266574d0.png)

**Mind:** Please don't grant users permanent sudo rights to this script, easy PrivEsc via Command Injection since I don't sanitize any input.

## Usage examples

```
sudo ./stageScan --ip 192.168.1.1 --vuln
sudo ./stageScan --ip 192.168.1.1 --rate=10000 --vuln --stylesheet
sudo ./stageScan --ip 192.168.1.1 --rate=500 --nmapUDP 100 -e tun0 --vuln
sudo ./stageScan --ip 192.168.1.1 --directory /home/dombg/outputDirectory/ --rate=800 -e tun0 --vuln
```
### List of IP's to check 

stageScan does not currently support a list of IP's to test. To get around this issue (still only sequential solution), you can make use of the xargs command and supply a list of ips, each in a new line.

`cat ips | xargs -I % /bin/bash -c 'sudo ./stageScan.sh --ip %'`

### Nmap UDP scans

First and foremost, performing reliable UDP scans is pretty hard due to its connection-less nature. While masscan can detect open UDP ports, nmap UDP scans can be a valuable addition. In the end it is a trade off between time (masscan) and accuracy (nmap). 

#### Why nmap scans might be more reliable

- **Protocol-specific payload**: "For most ports, this packet will be empty (no payload), but for a few of the more common ports a protocol-specific payload will be sent". These protocol-specific payloads can potentially trigger a application response which enables detection of open ports more reliably.
- **Version detection scans**: "Version detection (-sV) is often needed to differentiate open from filtered UDP ports". Again, same topic. -sV scans will send protocol-specific paylods to enumerate the service+version which might help detecting open ports.

#### How to speed up nmap UDP scans

- Redurce target ports to most common ports (`--top-ports`).
- `--version-intensity 0`, ".. directs Nmap to only try the probes most likely to be effective against a given port number". 

Resource: [nmap udp scans](https://nmap.org/book/scan-methods-udp-scan.html)



## Requirements

- [masscan](https://github.com/robertdavidgraham/masscan)
- [nmap](https://nmap.org/)
- xsltproc (only for --stylesheet option)

## Credits

[Honze-net bootstrap stylesheet](https://github.com/honze-net/nmap-bootstrap-xsl/), which is used to create a nice HTML output of the nmap results.

## Disclaimer

stageScan is written for network security assessments where the scanning is explicitly allowed by the owner of the target system/network, please use it responsively. I'm not responsible for any misuse of this tool.
