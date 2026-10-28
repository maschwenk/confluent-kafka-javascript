#!/bin/sh
# Node setup as in ci/post-install/install-{debian,rhel,alpine}.sh, then the
# mirror install instead of a published release. Usage: post-install.sh <node> <family>
set -e
case "$2" in
  debian)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq > /dev/null
    apt-get install -y -qq bash curl > /dev/null ;;
  rhel)
    dnf install --allowerasing -y -q bash curl > /dev/null ;;
esac
[ "$2" = alpine ] || . /v/ci/post-install/_install_nvm.sh
cat /etc/os-release | grep '^PRETTY_NAME'
ldd --version 2>&1 | head -1
sh /v/verify-node-26/install-from-mirror.sh /pkg/client.tgz
