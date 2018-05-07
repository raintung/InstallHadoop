#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

HOSTNAME=`hostname`

NN_FILE=$PROGDIR/../conf/namenode
DN_FILE=$PROGDIR/../conf/datanode
CONF_FILE=$PROGDIR/../conf/parameters
CONF_FOLDER=$PROGDIR/../conf/
PACKAGE_FOLDER=$PROGDIR/../package/
TEMPLATE_FOLDER=$PROGDIR/../template/
echo "[INFO] >>>>>>>>>>>>>>>> Check the setup's configuration  >>>>>>>>>>>>>>>>>>"
for file in $DN_FILE $NN_FILE
do
        while read line; do
        	set -- $line
        	echo "[INFO] Ping the node:$1 $2"
        	pingshell=`ping -c 1 -w 2 $2 2>&1`
		ping_result=$?
		if [ $ping_result -eq 2 ];then
			echo "[FAILE] Cannot ping successfully for $1"
			exit 1
		fi
	done < $file
done


MY_IP=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
for file in $NN_FILE
do
        while read line; do
        	set -- $line
        	if [ "$MY_IP" = "$2" ];  then
			if [ ! "$HOSTNAME" = "$1" ]; then
				echo "[INFO] Change the master hostname $HOSTNAME to $1"
				hostnamectl set-hostname $1
				exit 1
			fi
		fi
	done < $file
done

echo "[INFO] Check the default folder and configuration file exist."
if [ ! -d $PACKAGE_FOLDER ] || [ ! -d $CONF_FOLDER ] || [ ! -d $TEMPLATE_FOLDER ] ||  [ ! -f $NN_FILE ]  || [ ! -f $DN_FILE ]; then
	echo "[FAILE] The default folder miss, quit the setup process."
	exit 1
fi

echo "[INFO] Check the conf file [$CONF_FILE]."

USER=`grep username  $CONF_FILE  2>/dev/null`
USER_PASSWORD=`grep password  $CONF_FILE  2>/dev/null`
USER_GROUP=`grep usergroup  $CONF_FILE  2>/dev/null`
WORK_FOLDER=`grep install_path  $CONF_FILE  2>/dev/null`
COMPONENTS=`grep install_components  $CONF_FILE  2>/dev/null`

if [ "$USER" = "" ] || [ "$USER_GROUP" = "" ] || [ "$USER_PASSWORD" = "" ] || [ "$WORK_FOLDER" = "" ]; then
        echo "[FAILE] The parameters file miss configuration, file:$CONF_FILE"
	exit 1
fi
echo "[INFO] >>>>>>>>>>>>>>>> Check the setup's configuration complete >>>>>>>>>>>>>>>>>>"


USER="${USER#*=}"
USER_PASSWORD="${USER_PASSWORD#*=}"
USER_GROUP="${USER_GROUP#*=}"
WORK_FOLDER="${WORK_FOLDER#*=}"
COMPONENTS="${COMPONENTS#*=}"
ARR_COMP=(${COMPONENTS//,/ })

echo "[INFO] ............... Generate root ssh key in the master .................."
SSH_HOME=~/.ssh
[ ! -d ~/.ssh ] && ( mkdir ~/.ssh ) && ( chmod 700 ~/.ssh )
[ ! -f ~/.ssh/id_rsa.pub ] && (yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N "") && ( chmod 600 ~/.ssh/id_rsa.pub )

echo "[INFO] ############### Begin config the full cluster  #################"
IFS=$'\n' read -d '' -r -a dnnodes < $DN_FILE
for line in "${dnnodes[@]}"
do
	set -- $line
	echo "[INFO] <<<<<<<<<<<<<<<<<<<<  Setup the DataNode [$1] ip: [$2]  >>>>>>>>>>>>>>>>>>>"
 	echo "[INFO] Set the SSH no password in the DataNode $1 ip: $2 name: $3 password: $4  $PROGDIR"
        expect $PROGDIR/ssh_nopassword.expect $2 $3 $4 $SSH_HOME >/dev/null 2>&1
 	echo "[INFO] Create the user_group $USER_GROUP in the Node $1 $2"
	ssh $3@$2 "addgroup $USER_GROUP"
 	echo "[INFO] Create the user $USER in the Node $1 $2"
	ssh $3@$2 "useradd -g $USER_GROUP $USER -s /bin/bash -m"
 	echo "[INFO] Create the user password $USER:$USER_PASSWORD in the Node $1 $2"
	ssh $3@$2 "echo $USER:$USER_PASSWORD | chpasswd"
 	echo "[INFO] Change the hostname:$1 in the Node $1 $2"
	ssh $3@$2 "hostnamectl set-hostname $1"
 	echo "[INFO] Copy the files $CONF_FOLDER to the Node $1 $2 tmp file"
	scp -rq $CONF_FOLDER $3@$2:$WORK_FOLDER
	ssh $3@$2 "chmod -fR 777 $WORK_FOLDER/conf"
 	echo "[INFO] Copy the files $PACKAGE_FOLDER to the Node $1 $2 tmp file"
	scp -rq $PACKAGE_FOLDER $3@$2:$WORK_FOLDER
	ssh $3@$2 "chmod -fR 777 $WORK_FOLDER/package"
	echo "[INFO] Copy the files $TEMPLATE_FOLDER to the Node $1 $2 tmp file"
	scp -rq $TEMPLATE_FOLDER $3@$2:$WORK_FOLDER
	ssh $3@$2 "chmod -fR 777 $WORK_FOLDER/template"
 	echo "[INFO] Set the root config  $USER:$USER_PASSWORD in the Node $1 $2"
        ssh $3@$2 "export WORK_FOLDER=$WORK_FOLDER;`cat $PROGDIR/config_system_root.sh`"
 	#echo "[INFO] Setup the java config  $USER:$USER_PASSWORD in the Node $1 $2"
        #ssh $3@$2 "export COMPONENT_ENV=jvm;export WORK_FOLDER=$WORK_FOLDER;`cat $PROGDIR/install_component.sh`"
	echo "[INFO] Set the SSH no password in the DataNode $1 ip: $2 name: $USER password: $USER_PASSWORD  $PROGDIR"
	expect $PROGDIR/ssh_nopassword.expect $2 $USER $USER_PASSWORD $SSH_HOME >/dev/null 2>&1
 	echo "[INFO] Set the user:$USER config:config_system_user.sh  $USER:$USER_PASSWORD in the Node:[$1 $2]"
	ssh $USER@$2 "export WORK_FOLDER=$WORK_FOLDER;`cat $PROGDIR/config_system_user.sh`;source ~/.profile"	
	echo "[INFO] Set the user:$USER hadoop  $USER:$USER_PASSWORD in the Node:[$1 $2]"
	for key in "${!ARR_COMP[@]}"
	do 
		COMP=${ARR_COMP[$key]}
		USER_NAME=`grep "$COMP"_user  $CONF_FILE  2>/dev/null`
		if [ "$USER_NAME" = "" ]; then
			USER_NAME=$USER
		else
			USER_NAME="${USER_NAME#*=}"
			if [ ! "$USER_NAME" = "$USER" ] && [ ! "$USER_NAME" = "$3" ]; then
				echo "[FAILED] Install the component $COMP user $USER_NAME is not exist. #######"
				exit 1
			fi
		fi
		echo "[INFO] >>>>>>>>>>>>>>>>>> Install the component $COMP user $USER_NAME in the DataNode [$1] >>>>>>>>>>>>>>>>>>>>>>"
		if [ -f $PROGDIR/install_component.sh ]; then
        		ssh $USER_NAME@$2 "export COMPONENT_ENV=$COMP;export WORK_FOLDER=$WORK_FOLDER;`cat $PROGDIR/install_component.sh`"
		fi
		if [ -f $PROGDIR/config_$COMP.sh ]; then
        		ssh $USER_NAME@$2 "export WORK_FOLDER=$WORK_FOLDER;`cat $PROGDIR/config_$COMP.sh`"
		fi
	done
	echo "[INFO] <<<<<<<<<<<<<<<<<<<< Setup the DataNode [$1] ip: [$2]  finished. >>>>>>>>>>>>>>>>>>>"
done

echo "[INFO] Create the user $USER and $USER_GROUP in the master"
if [ $(getent group $USER_GROUP) ]; then
	echo "[INFO] Group $USER_GROUP exist, ignore create"
else
	echo "[INFO] Create the user group:$USER_GROUP"
	addgroup $USER_GROUP
fi

if [ $(getent passwd $USER) ]; then
	echo "[INFO] User $USER exist, ignore create"
else 
	echo "[INFO] Create the user $USER on master"
	useradd -g $USER_GROUP $USER -s /bin/bash -m
fi
echo "[INFO] User $USER change password $USER_PASSWORD"
echo $USER:$USER_PASSWORD | chpasswd


SSH_ROOT=/home/$USER/.ssh
echo "[INFO] Config $USER ssh in the master"
[ ! -d $SSH_ROOT ] && ( mkdir $SSH_ROOT ) && ( chmod 700 $SSH_ROOT ) && ( chown $USER:$USER_GROUP $SSH_ROOT)
if [ ! -f $SSH_ROOT/id_rsa.pub ]; then
	sshshell='ssh-keygen -f '$SSH_ROOT'/id_rsa -t rsa -N ""'
	echo "[info] SSH key generate $sshshell"
	su $USER -c "$sshshell"
fi

echo "[INFO] ................... Config master ssh nopassword login for cluster user .................."
for file in $DN_FILE $NN_FILE
do
	while read line; do    
	set -- $line
	echo "[INFO] <<<<<<<<<<<<<<<<<<<<  Setup the user $USER ssh nopassword login for [$1] ip: [$2]  >>>>>>>>>>>>>>>>>>>"
	echo "[INFO] DataNode $1 ip: $2 name: $3 password: $4 $PROGDIR"
	expectshell='expect '$PROGDIR'/ssh_nopassword.expect '$2' '$USER' '$USER_PASSWORD' '$SSH_ROOT''
	echo "[INFO] Execute expectshell [$expectshell]"
	su $USER -c "$expectshell"
	echo "[INFO] <<<<<<<<<<<<<<<<<<<<  Setup the user root ssh nopassword login for [$1] ip: [$2]  >>>>>>>>>>>>>>>>>>>"
        expect $PROGDIR/ssh_nopassword.expect $2 $USER $USER_PASSWORD $SSH_HOME >/dev/null 2>&1
	done < $file
done
echo "[INFO] ................... Config master ssh nopassword login for cluster user complete.................."
echo "[INFO] Execute the $PROGDIR/config_system_root.sh script"
export WORK_FOLDER=$WORK_FOLDER
sh $PROGDIR/config_system_root.sh
echo "[INFO] Install jvm envoriment"
#export COMPONENT_ENV=jvm
#sh $PROGDIR/install_component.sh
echo "[INFO] Execute the $PROGDIR/config_system_user.sh script"
su $USER -c "export WORK_FOLDER=$WORK_FOLDER;sh $PROGDIR/config_system_user.sh;source ~/.profile"
for key in "${!ARR_COMP[@]}"
do 
	COMP=${ARR_COMP[$key]}
	USER_NAME=`grep "$COMP"_user  $CONF_FILE  2>/dev/null`
	if [ "$USER_NAME" = "" ]; then
		USER_NAME=$USER
	else
		USER_NAME="${USER_NAME#*=}"
		if [ ! "$USER_NAME" = "root" ]; then
			USER_NAME=$USER
		else
			USER_NAME=""	
		fi
	fi
	echo "[INFO] >>>>>>>>>>>>>>>>>> Install the component $COMP user $USER_NAME >>>>>>>>>>>>>>>>>>>>>>"
	if [ -f $PROGDIR/install_component.sh ]; then
		su $USER_NAME -c "export COMPONENT_ENV=$COMP;export WORK_FOLDER=$WORK_FOLDER;bash $PROGDIR/install_component.sh"
	fi
	if [ -f $PROGDIR/config_$COMP.sh ]; then
		su $USER_NAME -c "export WORK_FOLDER=$WORK_FOLDER;bash $PROGDIR/config_$COMP.sh"
	fi
done

echo "[INFO] Setup the cluster successfully!"
