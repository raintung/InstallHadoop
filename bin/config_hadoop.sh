#!/bin/bash

HOSTNAME=`hostname`
CURRENT_USER=`whoami`
ROOT_PATH=${WORK_FOLDER}
if [ "$ROOT_PATH" = "" ]; then
        echo "[$HOSTNAME $CURRENT_USER FAILE] Work folder $ROOT_PATH is NULL, exit the setup for $COMPONENT enviroment."
        exit 1
fi

echo "[$HOSTNAME $CURRENT_USER INFO] Begin to config the hadoop"

NN_FILE=$ROOT_PATH/conf/namenode
DN_FILE=$ROOT_PATH/conf/datanode
CONF_FILE=$ROOT_PATH/conf/parameters
HADOOP_HOME=`grep hadoop_home  $CONF_FILE  2>/dev/null`
if [ ! "$HADOOP_HOME" = "" ]; then
        HADOOP_HOME="${HADOOP_HOME#*=}"
	if [ -L $HADOOP_HOME ] && [ -e $HADOOP_HOME ]; then	
        	echo "[$HOSTNAME $CURRENT_USER INFO] Config the user hadoop class path"
		echo  "
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export HADOOP_LIBEXEC_DIR=$HADOOP_HOME/libexec
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HDFS_CONF_DIR=$HADOOP_HOME/etc/hadoop
export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
">> ~/.bashrc

		source ~/.profile
		if [ -f $HADOOP_HOME/etc/hadoop/slaves ]; then
			rm $HADOOP_HOME/etc/hadoop/slaves
		fi
		while read line; do
                        set -- $line
			echo "[$HOSTNAME $CURRENT_USER INFO] Add $1 into slaves file"
                        echo "$1"$'\n' >> $HADOOP_HOME/etc/hadoop/slaves
                done < $DN_FILE

		while read line; do 
			set -- $line
			if [  "$HOSTNAME" = "$1" ]; then
				HOST=true
				break
			fi
		done < $NN_FILE
		if [ ! "$HOST" = "" ]; then
			echo "[$HOSTNAME $CURRENT_USER INFO] Only master Format the hadoop namenode"
			$HADOOP_HOME/bin/hadoop namenode -format
		fi
	fi
fi

echo "[$HOSTNAME $CURRENT_USER INFO] Config the hadoop success."
