#!/bin/sh

if [ ! -z "$DEBUG" ]
then
  # Have the DEBUG env var from Docker
  # This means we want the log level to be set to debug in both default and foo
  tee /drouter/config/debug.cfg <<-EOF
	# DEBUG log is enabled
	top; co
	logging target "debug-log"
	  type file
	  priority normal
	  soap-version soap11
	  format text
	  timestamp zulu
	  no fixed-format 
	  size 10000
	  local-file "logtemp:///debug-log"
	  archive-mode rotate
	  rotate 4
	  no ansi-color 
	  facility user
	  rate-limit 100
	  connect-timeout 60
	  idle-timeout 15
	  active-timeout 0
	  no feedback-detection 
	  no event-detection 
	  suppression-period 10
	  ssl-client-type proxy
	  event "all" "debug"
	exit
	EOF
  tee /drouter/config/foo/debug.cfg <<-EOF
	# DEBUG log is enabled
	top; co
	logging target "debug-log"
	  type file
	  priority normal
	  soap-version soap11
	  format text
	  timestamp zulu
	  no fixed-format 
	  size 10000
	  local-file "logtemp:///debug-log"
	  archive-mode rotate
	  rotate 4
	  no ansi-color 
	  facility user
	  rate-limit 100
	  connect-timeout 60
	  idle-timeout 15
	  active-timeout 0
	  no feedback-detection 
	  no event-detection 
	  suppression-period 10
	  ssl-client-type proxy
	  event "all" "debug"
	exit
	EOF
else
  # The DEBUG env var is not set in Docker; use loglevel info
  tee /drouter/config/debug.cfg <<-EOF
	# DEBUG log is not enabled
	EOF
  tee /drouter/config/foo/debug.cfg <<-EOF
	# DEBUG log is not enabled
	EOF
fi
