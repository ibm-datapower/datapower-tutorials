#!/bin/sh

{
  cat <<-EOF
	top; co

	loadbalancer-group lbg-backend
	  reset
	EOF

  ( env | grep '^[a-zA-Z0-9_-]*_PORT_8080_TCP_ADDR' | cut -d= -f2- ; nslookup backend | sed -n -e '/^$/,$p' | awk '/^Address /{print $4}'; ) \
  | while read ADDR
  do
    echo "  server $ADDR 1 8080 enabled"
  done

  cat <<-EOF
	exit

	xml-manager default
	  loadbalancer-group lbg-backend
	exit
	EOF
} | tee /drouter/config/foo/loadbalancer-group.cfg

