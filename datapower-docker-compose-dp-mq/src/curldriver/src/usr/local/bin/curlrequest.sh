#!/bin/bash
# set env vars to modify operation
# TIMEOUT=<time in seconds> for amount of time to continue to retry
# CONTINUOUS=true to continuously test, otherwise exits immediately on success

if [ "$TIMEOUT" -a "$TIMEOUT" -gt 0 ]
then
  STOPTIME=$(( $(date +%s) + $TIMEOUT ))
else
  STOPTIME=9999999999
fi

RC=1

while [ $(date +%s) -lt $STOPTIME ]
do
echo "SENDING REQUEST"
  if curl --silent --insecure --form "project=@/usr/local/bin/grow-soapui-project.xml" --form "suite=sendRequestGrow" http://soapui:3000 | grep "200 OK"
  then
    RC=0
    if [ "$CONTINUOUS" != "true" ]
    then
      echo "SUCCESS! Exiting"
      exit $RC
    fi
  else
    echo curl error $?
  fi
  sleep 5
done
