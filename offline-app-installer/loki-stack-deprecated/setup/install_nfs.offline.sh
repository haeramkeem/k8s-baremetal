#!/bin/bash

if [[ $1 != "server" && $1 != "client" ]]; then
    echo "Please specify the installation target"
    echo "* Synopsis: ./install.sh [server | client]"
    exit 1
fi

dpkg -i ./debs/nfs-$1/*.deb

if [[ $1 == "server" ]]; then
    mkdir /nfs_shared
    echo "/nfs_shared 192.168.1.0/24(rw,no_root_squash,no_subtree_check,sync)" >> /etc/exports
    systemctl enable --now nfs-server
    systemctl restart nfs-server
fi
