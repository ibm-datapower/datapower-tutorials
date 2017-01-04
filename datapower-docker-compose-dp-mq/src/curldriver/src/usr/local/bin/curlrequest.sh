#!/bin/bash
sleep 30

for (( i=1; i <= 5; i++ ))
  do
   echo "sending message $i"
     curl --silent --insecure --form "project=@/usr/local/bin/grow-soapui-project.xml" --form "suite=sendRequestGrow" http://soapui:3000 || echo curl error $?
   echo "response $i received"
  sleep 5
  done
