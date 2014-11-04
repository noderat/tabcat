#!/usr/bin/env bash

# Bash script to set up Couch DB for Tabcat
# Expects COUCHDB_URL environment variable to be set to point to Couch DB URL. E.g. http://127.0.0.1:5984

CONFIG_URL=$COUCHDB_URL/_config
HTTPD_AUTH_SECTION=$CONFIG_URL/couch_httpd_auth
UUIDS_SECTION=$CONFIG_URL/uuids
ADMINS_SECTION=$CONFIG_URL/admins
USERS_SECTION=$CONFIG_URL/users


echo "Creating admin user ..."
echo "Please enter Admin user's id:"
read ADMIN_USER
echo "Please enter Admin user's password:"
read -s ADMIN_PASSWORD
curl --header "Content-Type: application/json" -X PUT $ADMINS_SECTION/$ADMIN_USER -d '"'$ADMIN_PASSWORD'"'

AUTH_STRING=$ADMIN_USER:$ADMIN_PASSWORD

echo "Creating password for tabcat user ..."
TABCAT_PASSWORD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $USERS_SECTION/tabcat -d '"'$TABCAT_PASSWORD'"'
echo $TABCAT_PASSWORD > .tabcat_password

for db in tabcat tabcat-data
do
    echo "Creating '$db' database with correct permissions..."
    curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $COUCHDB_URL/$db
    curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $COUCHDB_URL/$db/_security -d '{"admins":{"names":["tabcat"],"roles":["admins"]}}'
done


echo "Configuring couch_httpd_auth ..."
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $HTTPD_AUTH_SECTION/allow_persistent_cookies -d '"true"'
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $HTTPD_AUTH_SECTION/timeout -d '"3600"'

echo "Configuring uuids ..."
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $UUIDS_SECTION/algorithm -d '"random"'
