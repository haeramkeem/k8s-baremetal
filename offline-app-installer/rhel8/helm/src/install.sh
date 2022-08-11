#!/bin/bash

WORKDIR=$(dirname $0)
INSTALL_DIR="/usr/local/bin"
SYMLINK_DIR="/usr/bin"

sudo mv $WORKDIR/bins/helm $INSTALL_DIR/helm
sudo chown $USER:$USER $INSTALL_DIR/helm
sudo chmod +x $INSTALL_DIR/helm
sudo ln -s $INSTALL_DIR/helm $SYMLINK_DIR/helm
