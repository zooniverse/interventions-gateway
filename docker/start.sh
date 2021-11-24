#!/bin/bash -e

cd /app
mkdir -p log/

if [ -f "/run/secrets/environment" ]
then
    source /run/secrets/environment
fi

exec bundle exec puma -C docker/puma.rb
