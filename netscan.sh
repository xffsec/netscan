#!/bin/bash

function ctrl_c(){
  echo -e "\n[!] Exiting..."
  kill -- -$$
}
trap ctrl_c INT

function banner(){

  echo '
  _  __    __  ____            
  / |/ /__ / /_/ __/______ ____ 
 /    / -_) __/\ \/ __/ _ `/ _ \
/_/|_/\__/\__/___/\__/\_,_/_//_/
 '
}


function help_panel(){
  if hostname -I > /dev/null; then 
    ip_addr_help="$( hostname -I | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'|head -n1 )"
  else
    ip_addr_help="192.168.1.1"
  fi

  echo -e "\n[i] Usage: $0"
  echo -e "\t-t) Target IP/Network: $ip_addr_help"
  echo -e "\t-N) Network scan of all active hosts: $0 -N -T $ip_addr_help "
  echo -e "\t-P) Port scan of all active hosts: $0 -P -T $ip_addr_help"
  echo -e "\t-p) Port scan of a singular host: $0 -p -t $ip_addr_help"
  echo -e "\t-r) Port range to scan (default 1-65535): $0 -p -t $ip_addr_help -r 80-9001"
  echo -e "\t-R) Network range to scan (default 1-255): $0 -N -T $ip_addr_help -R 1-20"
  echo -e "\t-s) Timeout for each ping/portscan (default 1): $0 -N -T $ip_addr_help -s 5"
  echo -e "\t-i) Find interfaces: $0 -i"
  echo -e "\nexample: bash $0 -P -t $ip_addr_help -R 1-100 -r 1-10000 -s 2" 

}

function interfaces(){
  echo "--- Interfaces ---"
  for interface in $(hostname -I); do 
    ((ifacenum+=1)); echo -e "[$ifacenum] $interface"
  done
}

function portscan(){
  echo -e "\n--- SCANNING PORTS ON EACH HOST - $network.$network_range:$port_range ---"
    for host in $(seq $(echo $network_range|tr '-' ' ')); do
    (
    ping -c 1 -w $time_out $network.$host >/dev/null 2>&1 && for port in $(seq $(echo $port_range|tr '-' ' ')); do
        ( 
          timeout $time_out echo > /dev/tcp/$network.$host/$port && echo -e "\t[+] $network.$host:$port" 
        )&
      done 2>/dev/null
      wait
    )&
    done
    wait
    echo "--- Finished scan ---"
}

function hostscan(){
  echo -e "\n--- SCAN ON NETWORK $network.$network_range ---"
  for host in $(seq $(echo $network_range|tr '-' ' ')); do
  ( 
  timeout $time_out ping -c 1 -w $time_out $network.$host >/dev/null 2>&1 && echo -e "\t[+] Active Host $network.$host" 
  ) &
  done
  wait
  echo "--- Finished scan ---"
}

function target_portscan(){
  echo -e "\n--- PORT SCANNING ON $target $port_range ---"
  for port in $(seq $(echo $port_range|tr '-' ' ')); do 
  (
    timeout $time_out echo > /dev/tcp/$target/$port && echo -e "\t[+] $target:$port"
  )&
  done 2>/dev/null
  wait
  echo "--- Finished scan ---"

}

# Parse the command-line options
while getopts "T:t:NPphr:R:s:i" arg; do
  case $arg in
    t) target=$OPTARG ;;
    N) flag_N=true ;;
    P) flag_P=true ;;
    p) flag_p=true ;;
    r) port_range=$OPTARG ;; 
    R) network_range=$OPTARG ;;
    s) time_out=$OPTARG ;;
    i) flag_i=true ;; 
    h) banner;;
  esac
done

network="$(echo $target | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}')"

if [ -z $port_range ]; then 
  port_range="1-65535"
fi

if [ -z $network_range ]; then
  network_range="1-255"
fi

if [ -z $time_out ]; then
  time_out="1"
fi


# Check for correct combinations of options
if [[ -n $flag_N && -n $network && -z $flag_P && -z $flag_p ]]; then
  hostscan
elif [[ -n $flag_P && -z $flag_N && -z $flag_p ]]; then
  portscan
elif [[ -n $flag_p && -n $target && -z $flag_N && -z $flag_P ]]; then
  target_portscan
elif [[ -n $flag_i ]]; then 
  interfaces 
else
  help_panel
  exit 1
fi
