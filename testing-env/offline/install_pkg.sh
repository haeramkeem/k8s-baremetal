#!/usr/bin/env bash

# install packages 
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# Configuration
echo 'alias vi=vim' >> /etc/profile
rm -rf ~/.vimrc
curl https://raw.githubusercontent.com/haeramkeem/rcs/main/.min.vimrc > ~/.vimrc
