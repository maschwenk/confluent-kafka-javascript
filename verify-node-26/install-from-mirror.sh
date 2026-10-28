#!/bin/sh
# Install the packed client without scripts, then fetch its prebuild through
# node-pre-gyp from the local mirror on :8000 that serves this workflow's
# artifacts, so the download URL node-pre-gyp computes is exercised. The
# mirror env var keeps a dash because node-pre-gyp only replaces the first.
set -eu
tgz=$1
app=$(mktemp -d)
cd "$app"
npm init -y > /dev/null
npm install --ignore-scripts --no-audit --no-fund "$tgz"
cd node_modules/@confluentinc/kafka-javascript
env 'npm_config_confluent_kafka-javascript_binary_host_mirror=http://127.0.0.1:8000/' \
  node "$app/node_modules/@mapbox/node-pre-gyp/bin/node-pre-gyp" install --fallback-to-build=false
cd "$app"
node -e 'console.log(process.version, require("@confluentinc/kafka-javascript").librdkafkaVersion);'
