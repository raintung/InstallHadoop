#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"
echo PROGNAME
echo PROGDIR
echo ARGS

if [ `id -u` -ne 0 ]; then
   echo "[ERROR] Must run as root privilege";  exit 1
fi

# Begin
echo "*******Welcome install hadoop cluster script********"
echo "Begin install Apache Hadoop cluster"
echo "Hostname is `hostname`, Time is `date +'%F %T'`, TimeZone is `date +'%Z %:z'`"
echo ""

bash $PROGDIR/bin/config_cluster.sh
echo "[INFO] Install hadoop on cluster complete!"
