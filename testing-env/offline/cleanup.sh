#!/usr/bin/env bash

mv /home/vagrant/setup.sh ~/dest/.
chmod 711 ~/dest/setup.sh
sed -i -e 's/\r$//' setup.sh
