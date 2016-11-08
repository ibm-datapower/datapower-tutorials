#!/bin/sh
#
# Work around the VBox/Docker Toolbox inotify bug [1] by disabling
# GatewayScript Cache. Note that if we had XSL, we would want
# to disable caches for that too.
#
# [1] https://www.virtualbox.org/ticket/10660

rm -f /drouter/config/vbox-inotify-workaround.cfg

if [ "$DP_VBOX_INOTIFY" = "true" ]
then
  tee /drouter/config/vbox-inotify-workaround.cfg <<-EOF
	# Working around https://www.virtualbox.org/ticket/10660
	# by disabling gatewayscript cache
	# We only do this when using GatewayScript with Docker
	# volumes when we expect to modify the GatewayScript itself
	# and want the changes to be immediately recognized.
	top; diag; set-gatewayscript-cache disable; top; config
	EOF
else
  tee /drouter/config/vbox-inotify-workaround.cfg <<-EOF
	# No need to work around https://www.virtualbox.org/ticket/10660
	EOF
fi
