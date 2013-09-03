#!/bin/sh

# Forcibly update a CouchDB doc

# Usage: ./force-put.sh filename URL [ mime-type ]
FILENAME=$1
URL=$2
MIME_TYPE=$3
if [ -z "$MIME_TYPE" ]; then MIME_TYPE=application-json; fi

# figure out CouchDB doc revision.
REV_URL=$(echo $URL | cut -d / -f 1-5)  # get parent doc's URL
REV=$(curl -X HEAD $REV_URL -I -s | grep ETag | cut -d '"' -f 2)
if [ -n "$REV" ]; then REV_QUERY="?rev=$REV"; fi

curl -X PUT "$URL$REV_QUERY" \
    -f -ss -H "Content-Type: $MIME_TYPE" --data-binary "@$FILENAME" > /dev/null
