#!/bin/sh
# If DP_RESET_PASSWORD=true, then set the admin password to one which is
# random and automatically generated. Note that the password for 'admin'
# is already persisted as standard config, and that password is the one
# we'll use for development. But when we deploy we do *not* want a well-
# known password to exist. Therefore we will reset it.

rm -f /drouter/config/reset-password-imp.cfg

if [ "$DP_RESET_PASSWORD" = "true" ]
then
  tee /drouter/config/reset-password-imp.cfg <<- EOF
	top; co
	user admin
	  password "$(tr -dc a-zA-Z0-9 < /dev/urandom | head -c 12)"
	exit
	delete config:///reset-password-imp.cfg
	EOF
fi
