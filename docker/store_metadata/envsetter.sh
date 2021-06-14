#!/usr/bin/env bash

printenv >> /etc/environment
rm -rf /virtuoso/metadataimport/*.ttl
echo "Start"
./download_NOMAD.sh

echo "Now importing ..."
./import.sh
