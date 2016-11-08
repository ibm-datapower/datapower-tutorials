#!/bin/sh

while true
do
  curl --silent --insecure https://datapower || echo curl error $?
  sleep 5
done
