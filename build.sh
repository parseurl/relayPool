#!/bin/bash
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  cp bin/relayPool-amd64 relayPool ;;
    aarch64) cp bin/relayPool-arm64 relayPool ;;
    armv7l)  cp bin/relayPool-armv7 relayPool ;;
    armv6l)  cp bin/relayPool-armv6 relayPool ;;
    *)       echo "Unsupported arch: $ARCH"; exit 1 ;;
esac
docker build -t relaypool .
rm -f relayPool
