#!/bin/bash

WORKDIR=$(dirname $0)

# Sort installed
mkdir $WORKDIR/rpms/installed
for rpm_file in $(ls $WORKDIR/rpms/nfs-utils/*.rpm); do
    rpm -q $(rpm -qp $rpm_file --nosignature) && mv $rpm_file $WORKDIR/rpms/installed/
done

# Resolve conflict
mv $WORKDIR/rpms/nfs-utils/dracut-*.rpm $WORKDIR/rpms/installed/
mv $WORKDIR/rpms/nfs-utils/glibc-*.rpm $WORKDIR/rpms/installed/
mv $WORKDIR/rpms/nfs-utils/grub2-*.rpm $WORKDIR/rpms/installed/
mv $WORKDIR/rpms/nfs-utils/libxml2-*.rpm $WORKDIR/rpms/installed/

# Install NFS-Server
sudo rpm -Uvh $WORKDIR/rpms/nfs-utils/*.rpm

# NFS Server scripts
NFS_PATH=/mnt/nfs_shared
MOUNT_PATH=/mnt/nfs_shared
ALLOW_CIDR="192.168.1.10/24"
NFS_SERVER="192.168.1.20"

if [[ $1 == "server" ]]; then
    sudo mkdir -pv $NFS_PATH
    sudo tee -a /etc/exports <<< "$NFS_PATH $ALLOW_CIDR(rw,no_root_squash,no_subtree_check,sync)"
    sudo systemctl enable --now nfs-server
    sudo systemctl restart nfs-server
    sudo exportfs -arv

    echo "Allowing NFS for firewalld: $(sudo firewall-cmd --permanent --add-service=nfs)"
    echo "Allowing RPC for firewalld: $(sudo firewall-cmd --permanent --add-service=rpc-bind)"
    echo "Allowing MountD for firewalld: $(sudo firewall-cmd --permanent --add-service=mountd)"
    echo "Reloading firewalld: $(sudo firewall-cmd --reload)"
fi

if [[ $1 == "client" ]]; then
    sudo mkdir -pv $MOUNT_PATH
    sudo mount -t nfs $NFS_SERVER:$NFS_PATH $MOUNT_PATH
    sudo tee -a /etc/fstab <<< "$NFS_SERVER:$NFS_PATH $MOUNT_PATH nfs defaults 0 0"
fi
