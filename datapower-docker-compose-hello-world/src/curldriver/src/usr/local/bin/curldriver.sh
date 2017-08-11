#!/bin/sh

while true
do
  curl --silent --insecure https://datapower:9443 || echo curl error $?
  sleep 5
done
