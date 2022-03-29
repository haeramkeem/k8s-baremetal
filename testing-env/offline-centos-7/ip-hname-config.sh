#!/bin/bash

if [[ $1 = "" ]] || [[ $2 = "" ]]
then
    echo "Please specify the hostname and IP in the valid format."
    echo "-> config.sh {hostname} {IP address 192.168.1.x}"
    exit 1
fi

# hostname config
hostnamectl set-hostname $1

# IP config
PATH=/etc/sysconfig/network-scripts/ifcfg-enp0s3
echo "IPADDR=$2" >> $PATH
echo "NETMASK=255.255.255.0" >> $PATH
echo "GATEWAY=192.168.1.1" >> $PATH
sed -i 's/dhcp/static/g' $PATH

# restart
reboot
