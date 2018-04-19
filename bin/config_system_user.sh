#!/bin/sh

addline(){
    line=$1
    file=$2
    tempstr=`grep "$line" $file  2>/dev/null`
    if [ "$tempstr" = "" ]; then
        echo "$line" >>$file
    fi
}

HOSTNAME=`hostname`
CURRENT_USER=`whoami`
echo "[$HOSTNAME $CURRENT_USER INFO] Config the user:$CURRENT_USER limits"
if [ ! -f /etc/security/limits.conf ]; then
	for user in hdfs mapred hbase zookeeper hive impala flume $curuser ;do
    		addline "$user	soft		nproc	131072" /etc/security/limits.conf
    		addline "$user	hard	nproc	131072" /etc/security/limits.conf
	done
else
	echo "[$HOSTNAME $CURRENT_USER INFO] /etc/security/limits.conf not found"
fi



echo "
 # .bashrc
 # Source global definitions
 if [ -f /etc/bashrc ]; then
    . /etc/bashrc
 fi
umask 022
" > ~/.bashrc

ROOT_PATH=${WORK_FOLDER}
CONF_FILE=$ROOT_PATH/conf/parameters
JVM_HOME=`grep jvm_home  $CONF_FILE  2>/dev/null`
if [ ! "$JVM_HOME" = "" ]; then
	echo "[$HOSTNAME $CURRENT_USER INFO] Config the user java class path"
	JVM_HOME="${JVM_HOME#*=}"
	if [ -f ~/.bashrc ] ; then
    		sed -i '/^export[[:space:]]\{1,\}JAVA_HOME[[:space:]]\{0,\}=/d' ~/.bashrc
    		sed -i '/^export[[:space:]]\{1,\}CLASSPATH[[:space:]]\{0,\}=/d' ~/.bashrc
    		sed -i '/^export[[:space:]]\{1,\}PATH[[:space:]]\{0,\}=/d' ~/.bashrc
	fi
	echo "export JAVA_HOME=$JVM_HOME" >> ~/.bashrc
	echo "export CLASSPATH=.:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar">>~/.bashrc
	echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
fi

HADOOP_HOME=`grep hadoop_home  $CONF_FILE  2>/dev/null`
if [ ! "$HADOOP_HOME" = "" ]; then
        echo "[$HOSTNAME $CURRENT_USER INFO] Config the user hadoop class path"
        HADOOP_HOME="${HADOOP_HOME#*=}"
        echo "export HADOOP_HOME=$HADOOP_HOME" >> ~/.bashrc
fi

cat $ROOT_PATH/conf/env >> ~/.bashrc

#source ~/.bash_profile
#source ~/.profile
