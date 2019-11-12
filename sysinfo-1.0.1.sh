#!/usr/bin/env bash

#
#  sysinfo - Display a summary of system hardware, operating system, and networking
#
#  Author:      Jed Record <erecord@lenovo.com>
#
#  Copyright (C) 2018, 2019 Jed Record, Lenovo, and contributors
#
#  Version:     1.0.1
#
#  Last update: 12 November 2019
#

# This program is free software; you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by the Free 
# Software Foundation; either version 2 of the License, or (at your option) 
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
# more details.

# You should have received a copy of the GNU General Public License along 
# with this program; if not, write to the Free Software Foundation, Inc., 51 
# Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

# Full license text at: https://spdx.org/licenses/GPL-2.0-or-later.html

# TODO: Use systemd-detect-virt to identify VMs?
# TODO: Substitute sed for complex gawk statements (ie: match, gsub)
# TODO: Produce alternative output for commands some systems do not support
#            eg: ip, ss, dmidecode, lscpu, df, du, xargs, tput, free

NAME="Sysinfo"
PURPOSE="Display a summary of system hardware, operating system, and networking"
VERSION="1.0.1"
UPDATED="12 Nov 2019"
AUTHOR="Jed Record"
EMAIL="erecord@lenovo.com"
WEB="https://jedrecord.com/software/sysinfo/latest"
COPYRIGHT="Copyright (C) 2018, 2019 Jed Record, Lenovo and contributors
License GPLv2+: GNU GPL version 2 or later <http://gnu.org/licenses/gpl.html>

This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law."
USAGE="Usage: sysinfo [OPTIONS]

Option          Meaning
 -a             Show all info available
 -d             Show disk usage
 -h             Show usage and options
 -l             Print a longer list of info than default
 -p             Show active services listening on TCP + UDP ports
 -s             Show a short summary
 -v             Print version info
 -w             List configured web directories"

#--------------------------------------
#             Main
#--------------------------------------
main()
{
  while getopts ":a :d :l :p :r: :s :v :w" opt; do
    case "$opt" in
        a) opt_all=true ;;
        d) opt_disk=true ;;
        l) opt_long=true ;;
        p) opt_ports=true ;;
        r) RHOST="$OPTARG";exec_remote ;;
        s) opt_short=true ;;
        v) show_version ;;
        w) opt_web=true ;;
       \?) show_help ;;
        :) echo "Opt ${OPTARG} requires an argumemt" 1>2& ;;
    esac
  done
  if [ $? -ne 0 ];then opt_none=true; fi
  shift $((OPTIND -1))
  
  begin
  if [ "$opt_short" = true ];then
    system
    show_os
    cpu
    mem
    exit 0;
  fi
  header
  name
#  ipaddr
  ethip4
  if [ "$opt_ports" = true ];then
#    iface
    tsvc
    usvc
    exit 0
  fi
  system
  show_os
  cpuinfo
  if [ "$opt_web" = true ];then web; exit 0; fi
  if [ "$opt_disk" = true ];then
    space
    dirs
    exit 0
  fi
  gpu
  mem
#  iface
  if [ "$opt_all" = true ] || [ "$opt_long" = true ];then
    tsvc
    usvc
  else
    tsvc
  fi
  # Stop here with no args (default)
  if [ "$opt_none" ];then
    exit 0
  fi
  if [ "$opt_long" = true ];then
    #dirs
    #askweb
    log
  elif [ "$opt_all" = true ];then
    space
    dirs
    web
    log
  fi
  exit 0 #-------- End --------
}

#--------------------------------------
#           Functions
#--------------------------------------
begin(){
  # If run from a terminal use colors
  if [[ -t 1 ]];then
    bold_text=$(tput bold)
    red_text=$(tput setaf 1)
    green_text=$(tput setaf 2)
    yellow_text=$(tput setaf 3)
    cyan_text=$(tput setaf 6)
    normal_text=$(tput sgr0)
  else
    bold_text=
    red_text=
    green_text=
    yellow_text=
    cyan_text=
    normal_text=
  fi
}
show_version(){
	echo "${NAME} version ${VERSION} (updated ${UPDATED})"
	echo "Email: ${EMAIL}   Web: ${WEB}"
	echo "${COPYRIGHT}"
	exit 0
}
show_help(){
	echo "${NAME} version ${VERSION} (updated ${UPDATED})"
	echo "${PURPOSE}"
	echo "${USAGE}"
	exit 0
}
exec_remote(){
  local sysinfo="$(cd "$(dirname "$0")" ; pwd -P )/$(basename "$0")"
  ssh "${RHOST}" "bash -s" < ${sysinfo}
  exit $?
}
header(){
  echo "-----------------------------------------------------"
}
name(){
  printf "Name: ${bold_text}%s${normal_text}\n" $(hostname)
}
ipaddr(){
  local ips=""
  for ipa in $(ip a|awk '/global/ {print $2}'|sed 's/\/.*//');do
    ips="${ipa}, ${ips}"
  done
  printf "IP addresses: ${ips%,*}\n"
}
ethip4(){
  local eips=""
  local interfaces=""
  if command -v gawk > /dev/null 2>&1;then
    interfaces="$(ip -4 -o a show scope global up | awk 'match($4,/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/,ip) {print $2":"ip[1]}')"
  else
    interfaces="$(ip -4 -o a show scope global up | awk '{print $2":"$4}'|sed "s/\/.*//")"
  fi
  local i=0
  for eip in ${interfaces};do
    if [[ $i -eq 0 ]]; then
      eips="${eip}"
      i=1
    else
      eips="${eips}, ${eip}"
    fi
  done
  printf "IP4 addresses: ${eips}\n"
}
system(){
  if [[ $EUID -eq 0 ]] && command -v dmidecode > /dev/null 2>&1;then
    mfg="$(dmidecode -s system-manufacturer)"
    prod="$(dmidecode -s system-product-name)"
  else
    mfg="$(cat /sys/devices/virtual/dmi/id/sys_vendor)"
    prod="$(cat /sys/devices/virtual/dmi/id/product_name)"
  fi
  arch="$(arch)"
  # Sometimes we see newlines in dmi output, supress with echo -n
  echo -n "System: ${mfg} ${prod} (${arch})"
  echo
}
show_os(){
  if [[ -f /etc/lsb-release ]];then
    source /etc/lsb-release
    os_string="${red_text}${DISTRIB_ID}${normal_text} ${DISTRIB_RELEASE}"
		if [[ -n "${DISTRIB_CODENAME}" ]];then
			os_string="${os_string} (${DISTRIB_CODENAME})"
		fi
  elif [[ -f /etc/os-release ]];then
    source /etc/os-release
    os_string="${red_text}${NAME}${normal_text} ${VERSION_ID}"
		if [[ -n "${VERSION_CODENAME}" ]];then
			os_string="${os_string} (${VERSION_CODENAME})"
		fi
  else
    os_string="${red_text}$(uname)${normal_text} Kernel: $(uname -r)"
  fi
  echo "OS: ${os_string} Kernel: $(uname -r)"
}
cpu(){
  if command -v gawk > /dev/null 2>&1;then
    cpucount="$(lscpu|awk -F: '/^CPU\(s\):/ {match($2,/([0-9]+)/,n);print n[1]}')"
    cpumodel="$(lscpu|awk -F: '/^Model name:/ {match($2,/\s+(\w.*)/,n);print n[1]}')"
  else
    cpucount="$(lscpu|awk -F: '/^CPU\(s\):/ {print $2}'|sed "s/ //g")"
    cpumodel="$(lscpu|awk -F: '/^Model name:/ {print $2}'|sed "s/^\s+//g")"
  fi
  printf "CPU Info: ${bold_text}%s${normal_text} x " $cpucount
  echo $cpumodel
}
cpuinfo(){
  cpu
  local skts=""
  local cps=""
  local tpc=""
  local cpucache=""
  if command -v gawk > /dev/null 2>&1;then
    skts="$(lscpu|awk -F: '/^Socket\(s\):/ {match($2,/([0-9]+)/,n);print n[1]}')"
    cps="$(lscpu|awk -F: '/^Core\(s\) per socket:/ {match($2,/([0-9]+)/,n);print n[1]}')"
    tpc="$(lscpu|awk -F: '/^Thread\(s\) per core:/ {match($2,/([0-9]+)/,n);print n[1]}')"
  else
    skts="$(lscpu|awk -F: '/^Socket\(s\):/ {print $2}'|sed "s/ //g")"
    cps="$(lscpu|awk -F: '/^Core\(s\) per socket:/ {print $2}'|sed "s/ //g")"
    tpc="$(lscpu|awk -F: '/^Thread\(s\) per core:/ {print $2}'|sed "s/ //g")"
  fi
  printf "%s sockets | %s cores per socket | %s threads per core | " \
    "${skts}" "${cps}" "${tpc}"
  if command -v numfmt > /dev/null 2>&1;then
    # If numfmt > 8.22
    #cpucache="$(cat /proc/cpuinfo|awk -F": " '/^cache size/ {print $2}'|numfmt -d _ --from=iec --to=iec --suffix=B --format="%.1f")"
    cpucache="$(cat /proc/cpuinfo|awk -F": " '/^cache size/ {print $2;exit;}'|numfmt -d _ --from=iec --to=iec --suffix=B)"
  else
    cpucache="$(cat /proc/cpuinfo|awk -F": " '/^cache size/ {print $2;exit;}')"
  fi
  echo "${cpucache} cache"
}
gpu(){
  if command -v nvidia-smi > /dev/null 2>&1;then
    #gpus="$(nvidia-smi --query-gpu=gpu_name 2> /dev/null)"
    #echo "GPU Info: ${bold_text}%s${normal_text}\n" "$gpus"
    echo "GPU(s):"
    nvidia-smi --query-gpu=gpu_name --format=csv,noheader 2> /dev/null
  fi
}
mem(){
  avail="$(free -h | awk '/Mem:/{print $2}')"
  freem="$(free -h | awk '/Mem:/{print $4}')"
  if [[ "$freem" =~ "M" ]];then
    freem="${red_text}$freem${normal_text}"
  fi
  printf "Total memory: %s Free memory: %s\n" "$avail" "$freem"
}
iface(){
  printf "Network interfaces: "
  for foo in $(ip link show up|grep -i "state up"|awk -F": " '{print $2}'); do
    printf "$foo "
  done
  echo
}
tsvc(){
  local ports=""
  printf "TCP ports listening: "
  if [[ $EUID -ne 0 ]];then
    if command -v gawk > /dev/null 2>&1;then
      ports="$(ss -ltn | awk 'NR>1 match($4,/.*:([0-9]+)$/,m){print m[1]}'|sort -u)"
    else
      ports="$(ss -ltn | awk 'NR>1 {print $4}'|sed -E "s/.*:([0-9]+)$/\\1/"|sort -u)"
    fi
    for tsrv in ${ports};do
      local tn="$(grep "\s${tsrv}/tcp" /etc/services|awk '{print $1}')"
      if [[ -z "${tn}" ]];then
        printf "%s " "${tsrv}"
      else
        printf "%s(%s) " "${tsrv}" "${tn}"
      fi
      done
    echo
  else
    if command -v gawk > /dev/null 2>&1;then
      ports="$(ss -pltn | awk 'NR>1 {{match($4,/.*:([0-9]+)$/,port) match($6,/users:\(\(\"([a-z][-a-z0-9_.]+)\"/,name)} {print name[1]"("port[1]")"}};' | sort -u)"
    else
      ports="$(ss -pltn | awk 'NR>1 {print $4,$6}' |sed -E "s/.*:([0-9]+) users:\(\(\"([^\"]+).*/\\1(\\2)/"|sort -u)"
    fi
    for tsrv in ${ports};do
      printf "$tsrv "
    done
    echo
  fi
}
usvc(){
  local ports=""
  printf "UDP ports listening: "
  if [[ $EUID -ne 0 ]];then
    if command -v gawk > /dev/null 2>&1;then
      ports="$(ss -lun | awk 'NR>1 match($4,/.*:([0-9]+)/,m){print m[1]}'|sort -u)"
    else
      ports="$(ss -lun | awk 'NR>1 {print $4}'|sed -E "s/.*:([0-9]+)$/\\1/"|sort -u)"
    fi
    for usrv in ${ports};do
      local un="$(grep "\s${usrv}/udp" /etc/services|awk '{print $1}')"
      if [[ -z "${un}" ]];then
        printf "%s " "${usrv}"
      else
        printf "%s(%s) " "${usrv}" "${un}"
      fi
    done
    echo
  else
    if command -v gawk > /dev/null 2>&1;then
      ports="$(ss -plun | awk 'NR>1 {{match($4,/.*:([0-9]+)$/,port) match($6,/users:\(\(\"([a-z][-a-z0-9_.]+)\"/,name)} {print name[1]"("port[1]")"}};' | sort -u)"
    else
      ports="$(ss -plun | awk 'NR>1 {print $4,$6}' |sed -E "s/.*:([0-9]+) users:\(\(\"([^\"]+).*/\\1(\\2)/"|sort -u)"
    fi
    for usrv in ${ports};do
      printf "$usrv "
    done
    echo
  fi
}
body() {
    IFS= read -r header
    printf '%s\n' "$header"
    "$@"
}
space(){
  echo "Disk space: "
  #df -h --output=target,size,avail,pcent -t xfs -t ext3 -t ext4
  df -h --output=target,fstype,size,avail,pcent \
    | body sort -rhk 5 \
    | grep -v 'tmpfs'
}
dirs(){
  echo
  printf "Gathering filesystem info, this may take a minute..."
  local homes="$(du -sh /home/* 2>/dev/null | sort -rh | head -5)"
  local vars="$(du -sh /var/* 2>/dev/null | sort -rh | egrep '^[0-9][0-9][0-9]+M|^[0-9.]+G' | head -5)"
  if command -v tput > /dev/null 2>&1; then
    # Clear to beginning of line
    printf $(tput el1)
    # Move cursor left 52 spaces (Back to beginning of line)
    printf $(tput cub 52)
    # Move cursor up 1 line
    printf $(tput cuu1)
  else
    # Mover cusor back 52 spaces (to beginning of line)
    echo -en "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    # Overight previous text
    echo -n "                                                    "
    # Move cursor back to beginning of line
    echo -en "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
  fi
  if [[ ! -z ${homes+x} ]]; then
    echo "Top home directories by size: "
    echo "${homes}"
  fi
  if [[ ! -z ${vars+x} ]]; then
    echo "Large var directories: "
    echo "${vars}"
  fi
}
web(){
  find /etc/apache2 -name "*.conf" 2>/dev/null \
    | xargs egrep -i '^ServerName\s+\w|^ServerRoot\s+\w|^<Directory ' \
    | awk -F ":" 'gsub(/\s+/," ",$2){print "apache2:"$2}' \
    | sed "s/apache2: /apache2:/" \
    | sed -r "s/<Directory \"?([^>\"]+).*/Dir:\1/" \
    | sort -r -u
  find /etc/httpd -name "*.conf" 2>/dev/null \
    | xargs egrep -i '^ServerName\s+\w|^DocumentRoot\s+\w|^<Directory ' \
    | awk -F ":" 'gsub(/\s+/," ",$2){print "httpd:"$2}' \
    | sed "s/httpd: /httpd:/" \
    | sed -r "s/<Directory \"?([^>\"]+).*/Dir:\1/" \
    | sort -r -u
  find /etc/nginx /etc/nginx -name "*.conf" 2>/dev/null \
    | xargs egrep -i "server_name\s+\w|location\s+\w|root\s+\w|alias\s+\w|mirror\s+\w" \
    | awk -F ":" 'gsub(/\s+/," ",$2) {print "nginx:"$2}' \
    | sed "s/nginx: /nginx:/" \
    | sed -r "/[^ ]+ [^a-zA-Z]+$/d" \
    | sed "/^nginx:#/d" \
    | sort -r -u
}
askweb(){
  if command -v gawk > /dev/null 2>&1;then
    echo "Web shares: "
    webcount=$(web | wc -l)
    web | head -10
    if [ "$webcount" -gt 10 ]; then
      echo "Press q to quit or any other key to view the more than 10 web directories"
      if read -r -n1 -t 5 -s key_in && [ "$key_in" != "q" ];then
        web | awk 'NR>10 {print}'
      fi
    fi
  elif [ "$opt_web" = true ];then
    echo "Skipping web directories (requires gawk)"
  fi
}
# Not sure how usefull this is, but I think it gives an idea of server health
# TODO: Smart checking of which log to check based on system
log(){
  if [[ $EUID -eq 0 ]];then
    local logsize="$(wc -l /var/log/messages|awk '{print $1}')"
    if [[ "${logsize}" -gt 0 ]];then
      local warnings="$(egrep -i "fail|error" /var/log/messages | wc -l)"
      local warnpct="$(awk -v W="${warnings}" -v L="${logsize}" 'BEGIN {print ((W * 100) / L)}')"
      printf '%s warnings in %s log entries: %.1f%% log error rate\n' "${warnings}" "${logsize}" "${warnpct}"
    fi
  fi
}

#--------------------------------------
#           end functions
#--------------------------------------
main "$@"