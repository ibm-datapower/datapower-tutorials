#!/bin/sh
# This is rather like run-parts. The purpose of this script is
# to call separate scriptlets that each generate some DataPower
# configuration. Once all the DataPower configuration is generated,
# then it exec's drouter.

set -x

# Ensure all the DATAPOWER_ env vars are available to drouter.
export $(env | grep ^DATAPOWER_ | cut -d= -f1)

# source each of the scriptlets ala run-parts:
for f in $(find /start -type f -name \*.sh ! -name .\*)
do
  echo "Processing $f"
  . "$f"
  set -x
  echo
done

# exec drouter with all orig args
exec /bin/drouter "$@"
