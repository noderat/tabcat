#!/bin/bash
sudo apt-get update -y    ##this step will add 5-10 minutes in initial provision
sudo apt-get install curl tar vim git -y #nodejs npm couchdb kmod-VirtualBox -y
#sudo npm install -g kanso coffee-script uglify-js coffeelint -y

curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install couchdb -y
sudo apt-get autoremove
sudo chown -R couchdb /var/run/couchdb
sudo chown -R vagrant /home/vagrant/.npm
#do NOT install nodejs as root user
apt-get install nodejs -y
npm install -g npm@3.x-latest
#installing these globally for now until they can be used with gulp
npm install -g kanso coffee-script uglify-js coffeelint -y
sudo su -c "gem install sass"
#skipping npm install for now
#cd /vagrant && npm install