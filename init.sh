#!/bin/bash
sudo apt-get update -y    ##this step will add 5-10 minutes in initial provision
sudo apt-get install curl tar vim git couchdb -y
#sudo apt-get install couchdb -y
sudo apt-get autoremove
sudo chown -R couchdb /var/run/couchdb

#install nvm to avoid permissions issues
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash
#because source ~/.bashrc did not work
source ~/.nvm/nvm.sh
nvm install stable -y
nvm use stable
#so that we can use node right away
nvm alias default node

#installing these globally for now until they can be used with gulp
npm install -g gulp kanso coffee-script uglify-js coffeelint -y

#required for sass compilation
sudo su -c "gem install sass"

#skipping npm install for now, re-enable later
#cd /vagrant && npm install