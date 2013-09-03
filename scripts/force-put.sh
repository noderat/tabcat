#!/bin/sh

# Forcibly update a CouchDB doc

# Usage: ./force-put.sh filename URL [ mime-type ]
FILENAME=$1
URL=$2
MIME_TYPE=$3
if [ -z "$MIME_TYPE" ]; then MIME_TYPE=application-json; fi

# figure out CouchDB doc revision.
REV_URL=$(echo $URL | cut -d / -f 1-5)  # get parent doc's URL
REV=$(curl -i -I -s -X HEAD $REV_URL | grep ETag | cut -d '"' -f 2)
if [ -n "$REV" ]; then REV_QUERY="?rev=$REV"; fi

curl -f -X PUT "$URL$REV_QUERY" -H "Content-Type: $MIME_TYPE" --data-binary "@$FILENAME"
