[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Bash version](https://img.shields.io/badge/Bash-v4-4EAA25?logo=GNU-bash)](https://github.com/jedrecord/sysinfo)
[![SUSE version](https://img.shields.io/badge/SLE-11+-73BA25?logo=openSUSE)](https://github.com/jedrecord/sysinfo)
[![Red Hat version](https://img.shields.io/badge/RHEL-7.1+-EE0000?logo=Red-Hat)](https://github.com/jedrecord/sysinfo)
[![Twitter Follow](https://img.shields.io/twitter/follow/jedrecord?label=follow&style=social)](https://twitter.com/jedrecord)

# sysinfo
Display a brief summary of system hardware, operating system, and networking for a host

sysinfo will also tell you if the host you're logged in to is a VM or container

```
Usage: sysinfo [OPTIONS]

Option          Meaning
 -a             Show detailed system information
 -d             Show disk usage
 -h, --help     Show usage and options
 -l             Print a longer list of info than default
 --license      Print full program license to the screen
 -p             Show active services listening on TCP + UDP ports
 -s             Show a short summary
 -v, --version  Print version info
 -w             List configured web directories
```

Default action is to print hostname, active IP addresses and interfaces, machine and os, CPU(s), RAM, and active listening TCP ports

```
$ sysinfo
Name: system42.internal-dc.amazon.com
IP4 addresses: eth0:172.16.36.150, eth1:192.168.157.1, docker0:172.17.0.1
System: VMware, Inc. VMware Virtual Platform (x86_64)
OS: Red Hat Enterprise Linux Server 7.8 Kernel: 3.10.0-957.46.1.el7.x86_64
CPU Info: 4 x Intel(R) Xeon(R) CPU E7-8880 v3 @ 2.30GHz
4 sockets | 1 cores per socket | 1 threads per core | 45MB cache
Total memory: 62G Free memory: 26G
TCP ports listening: 22(ssh) 443(https) 80(http)
```

## Installation
```
sudo curl -s https://raw.githubusercontent.com/jedrecord/sysinfo/master/sysinfo \
  -o /usr/bin/sysinfo && sudo chmod 755 /usr/bin/sysinfo
```
