#!/bin/sh

set -ex

if [ "$0" != "./tidy.sh" ]
then
  echo ERROR: $0 can only be run from its directory >&2
  exit 1
fi

GENERATED="datapower/src/drouter/config/debug.cfg \
      datapower/src/drouter/config/foo/debug.cfg \
      datapower/src/drouter/config/foo/loadbalancer-group.cfg \
      datapower/src/drouter/config/vbox-inotify-workaround.cfg \
      datapower/src/drouter/config/web-mgmt.cfg \
      "

if uname | grep -i Linux >/dev/null 2>&1
then
  sudo chown -R --reference=$HOME datapower/src
fi
# leave the bits alone, but make sure everything drouter
# might change is readable by all, writable by the user,
# and not writable by the group and other.
find datapower/src | xargs chmod u+rw,g+r,o+r,g-w,o-w

rm -f .gitignore $GENERATED

for f in $GENERATED
do
  echo $f >> .gitignore
done

# Remove web-mgmt section
sed -i -e '/^web-mgmt/,/^exit/d' datapower/src/drouter/config/auto-startup.cfg
