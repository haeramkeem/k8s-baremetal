#!/bin/bash

WORKDIR=$(dirname $0)

# Install Keepalived
mkdir -pv $WORKDIR/rpms/installed
for rpm_file in $(ls $WORKDIR/rpms/keepalived/*.rpm); do
    rpm -q $(rpm -qp $rpm_file --nosignature) && mv $rpm_file $WORKDIR/rpms/installed/
done

mv $WORKDIR/rpms/keepalived/dracut*.rpm $WORKDIR/rpms/installed
mv $WORKDIR/rpms/keepalived/grub2*.rpm $WORKDIR/rpms/installed
mv $WORKDIR/rpms/keepalived/libxml*.rpm $WORKDIR/rpms/installed
mv $WORKDIR/rpms/keepalived/glibc*.rpm $WORKDIR/rpms/installed

sudo rpm -Uvh --force $WORKDIR/rpms/keepalived/*.rpm

# Setup configuration
sudo cp $WORKDIR/etcs/keepalived.$1.conf /etc/keepalived/keepalived.conf
CHECK_SCRIPT_FNAME="health_chk.sh"
NIC_NAME="enp0s3"
VIP="192.168.1.10"
sudo sed -i "s/\${CHECK_SCRIPT_FNAME}/$CHECK_SCRIPT_FNAME/g" /etc/keepalived/keepalived.conf
sudo sed -i "s/\${NIC_NAME}/$NIC_NAME/g" /etc/keepalived/keepalived.conf
sudo sed -i "s/\${VIP}/$VIP/g" /etc/keepalived/keepalived.conf

# Setup health check script
sudo cp $WORKDIR/etcs/health_chk.sh /etc/keepalived/$CHECK_SCRIPT_FNAME
sudo sed -i 's/\r//g' /etc/keepalived/$CHECK_SCRIPT_FNAME
sudo chown root:root /etc/keepalived/$CHECK_SCRIPT_FNAME
sudo chmod +x /etc/keepalived/$CHECK_SCRIPT_FNAME
sudo chcon -t keepalived_unconfined_script_exec_t /etc/keepalived/$CHECK_SCRIPT_FNAME
