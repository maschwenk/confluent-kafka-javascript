#!/bin/sh
# Pack the Kafka client with the given Makefile.base, then npm install it on
# Node 26, where no prebuild exists, so node-pre-gyp falls back to a source
# build under node_modules/@confluentinc/kafka-javascript.
set -u
MK=$1
expect=$2
node -v
mkdir -p /pkg && cp -a /src/. /pkg/ && cd /pkg || exit 2
cp "$MK" deps/librdkafka/mklove/Makefile.base
rm -rf deps/librdkafka/.git build node_modules
tgz=$(npm pack --ignore-scripts --silent 2>/dev/null | tail -1); ls -la "/pkg/$tgz" || exit 3
mkdir /app && cd /app && npm init -y > /dev/null
npm install --foreground-scripts --no-audit --no-fund "/pkg/$tgz" > /app/install.log 2>&1; rc=$?
echo "npm install exit=$rc"
grep -E 'node-v147|404|Pre-built binaries not installable|Creating self-contained|Syntax error|file format not recognized|gyp info ok|gyp ERR! (stack|code)|fatal error' /app/install.log | head -12
if [ "$expect" = fail ]; then
  [ $rc -ne 0 ] && grep -q -E 'Syntax error in archive script|file format not recognized' /app/install.log && { echo "PASS: failed at the ar step as expected"; exit 0; }
  tail -40 /app/install.log; echo "FAIL: expected the ar step to fail"; exit 1
fi
[ $rc -eq 0 ] || { tail -60 /app/install.log; exit $rc; }
node -e '
const k = require("@confluentinc/kafka-javascript");
console.log("librdkafka", k.librdkafkaVersion);
console.log("features", k.features.join(","));
const p = new k.KafkaJS.Kafka({ kafkaJS: { brokers: ["localhost:9092"] } }).producer();
console.log("producer constructed:", typeof p.connect === "function");
'
ldd /app/node_modules/@confluentinc/kafka-javascript/build/Release/confluent-kafka-javascript.node 2>/dev/null | awk '{print $1}' | tr '\n' ' '; echo
