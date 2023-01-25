#!/usr/bin/env bash

PORT=$1

echo -n "Waiting for port ${PORT} to be open ...";
for _ in $(seq 1 60); do
  nc -w 1 -z localhost "${PORT}" 2>/dev/null && echo "" && exit
  sleep 1
  echo -n "."
done
echo " timeout after 60 seconds!" >&2; exit 1
