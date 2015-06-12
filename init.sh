#!/bin/bash

sudo groupadd vboxsf
sudo usermod -aG vboxsf $(whoami)
sudo modprobe -a vboxguest vboxsf
#sudo yum update -y    ##this step will add 5-10 minutes in initial provision
sudo yum install vim git nodejs npm couchdb kmod-VirtualBox -y
sudo iptables -A  IN_public_allow -p tcp -m tcp --dport 5984 -m conntrack --ctstate NEW -j ACCEPT  ## need to find a way to make this permanent
sudo npm install -g kanso coffee-script uglify-js coffeelint -y