{
  if [ "$DP_WEB_MGMT" = "true" ]
  then
    cat <<-EOF
	top; co

	web-mgmt
	  reset
	  admin enabled
	  idle-timeout 0
	exit
	EOF
  else
    cat <<-EOF
	top; co

	web-mgmt
	  admin disabled
	exit
	EOF
  fi
} | tee /drouter/config/web-mgmt.cfg
