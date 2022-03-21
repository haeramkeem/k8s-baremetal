#!/usr/bin/env bash
# install packages 
yum install epel-release -y
yum install vim-enhanced -y
curl https://raw.githubusercontent.com/haeramkeem/rcs/main/.min.vimrc > ~/.vimrc
