#!/bin/bash

WORKDIR=$(dirname $0)

# Sort installed
mkdir $WORKDIR/rpms/installed
for rpm_file in $(ls $WORKDIR/rpms/*.rpm); do
    rpm -q $(rpm -qp $rpm_file --nosignature) && mv $rpm_file installed/
done

# Resolve conflict
mv $WORKDIR/rpms/dracut-*.rpm $WORKDIR/rpms/installed/
mv $WORKDIR/rpms/glibc-*.rpm $WORKDIR/rpms/installed/
mv $WORKDIR/rpms/grub2-*.rpm $WORKDIR/rpms/installed/
mv $WORKDIR/rpms/libxml2-*.rpm $WORKDIR/rpms/installed/

sudo rpm -Uvh --force $WORKDIR/rpms/*.rpm
