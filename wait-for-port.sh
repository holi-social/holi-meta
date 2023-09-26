#!/usr/bin/env bash

PORT=$1

if ! command -v nc &>/dev/null; then
  echo "Error: netcat (nc) is not installed. Please install it to use this script."
  exit 1
fi

echo -n "Waiting for port ${PORT} to be open ...";
for _ in $(seq 1 60); do
  if nc -w 1 -z localhost "${PORT}" 2>/dev/null ; then 
    echo ""
    exit
  fi
  sleep 1
  echo -n "."
done
echo " timeout after 60 seconds!" >&2; exit 1
