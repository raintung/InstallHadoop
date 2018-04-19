#!/bin/sh

addline() {
    line=$1
    file=$2
    tempstr=`grep "$line" $file  2>/dev/null`
    if [ "$tempstr" = "" ]; then
        echo "$line" >>$file
    fi
}

HOSTNAME=`hostname`
ROOT_PATH=${WORK_FOLDER}
DN_FILE=$ROOT_PATH/conf/datanode
NN_FILE=$ROOT_PATH/conf/namenode
echo "[$HOSTNAME INFO] Config host file"
while read line; do
        set -- $line
        echo "[$HOSTNAME INFO] Add the DataNode $1 ip: $2"
	addline "$2 $1" /etc/hosts
done < $DN_FILE
while read line; do
        set -- $line
        echo "[$HOSTNAME INFO] Add the NameNode $1 ip: $2"
	addline "$2 $1" /etc/hosts
done < $NN_FILE




echo  "[$HOSTNAME INFO] Disable firewalls in the $HOSTNAME"
[ -f /etc/init.d/iptables ] && FIREWALL="iptables"
[ -f /etc/init.d/SuSEfirewall2_setup ] && FIREWALL="SuSEfirewall2_setup"
[ -f /etc/init.d/boot.apparmor ] && SELINUX="boot.apparmor"
[ -f /usr/sbin/setenforce ] && SELINUX="selinux"
service $FIREWALL stop >/dev/null 2>&1
chkconfig $FIREWALL off > /dev/null 2>&1

if [ "$SELINUX" = "selinux" ]; then
    sed -i "s/.*SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config
    setenforce 0  >/dev/null 2>&1
elif [ "$SELINUX" = "boot.apparmor" ]; then
    service boot.apparmor stop >/dev/null 2>&1
    chkconfig boot.apparmor off > /dev/null 2>&1
fi

echo "[$HOSTNAME INFO] Config ssh"
[ ! -d ~/.ssh ] && ( mkdir ~/.ssh ) && ( chmod 600 ~/.ssh )
[ ! -f ~/.ssh/id_rsa.pub ] && (yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N "") && ( chmod 600 ~/.ssh/id_rsa.pub )

addline "StrictHostKeyChecking no" ~/.ssh/config
addline "UserKnownHostsFile /dev/null" ~/.ssh/config
addline "LogLevel ERROR" ~/.ssh/config

echo "[$HOSTNAME INFO] Config system params"
sysctl -w vm.swappiness=0 >/dev/null
echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag" >/etc/rc.local
rst=`grep "^fs.file-max" /etc/sysctl.conf`
if [ "x$rst" = "x" ] ; then
	echo "fs.file-max = 727680" >> /etc/sysctl.conf || exit $?
else
	sed -i "s:^fs.file-max.*:fs.file-max = 727680:g" /etc/sysctl.conf
fi

echo "[$HOSTNAME INFO] Config system limits params"
addline "*	soft		nofile	327680" /etc/security/limits.conf
addline "*	hard	nofile	327680" /etc/security/limits.conf
addline "root	soft		nofile	327680" /etc/security/limits.conf
addline "root	hard	nofile	327680" /etc/security/limits.conf



