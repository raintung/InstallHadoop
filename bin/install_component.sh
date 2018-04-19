#!/bin/sh

HOSTNAME=`hostname`
CURRENT_USER=`whoami`
COMPONENT=${COMPONENT_ENV}
echo "[$HOSTNAME $CURRENT_USER INFO] Begin to install the $COMPONENT"


if [ "$COMPONENT" = "" ]; then
	echo "[$HOSTNAME $CURRENT_USER FAILE] $COMPONENT is NULL, exit the setup for $COMPONENT enviroment."
	exit 1
fi

ROOT_PATH=${WORK_FOLDER}
if [ "$ROOT_PATH" = "" ]; then
        echo "[$HOSTNAME $CURRENT_USER FAILE] Work folder $ROOT_PATH is NULL, exit the setup for $COMPONENT enviroment."
        exit 1
fi

CONF_FILE=$ROOT_PATH/conf/parameters
FOLDER=`grep "$COMPONENT"_folder  $CONF_FILE  2>/dev/null`
INSTALL=`grep "$COMPONENT"_install  $CONF_FILE  2>/dev/null`
HOME=`grep "$COMPONENT"_home  $CONF_FILE  2>/dev/null`

if [ "$FOLDER" = "" ] || [ "$INSTALL" = "" ] || [ "$HOME" = "" ]; then
        echo "[$HOSTNAME $CURRENT_USER FAILE] Setup the $COMPONENT environment failed. The parameters file miss configuration, file:$CONF_FILE"
        echo "[$HOSTNAME $CURRENT_USER FAILE] Exit the setup for $COMPONENT enviroment."
        exit 1
fi


FOLDER="${FOLDER#*=}"
INSTALL="${INSTALL#*=}"
HOME="${HOME#*=}"

FOLDER_SRC=$ROOT_PATH/package/$FOLDER

if [ ! -d $FOLDER_SRC ]; then
	echo "[$HOSTNAME $CURRENT_USER FAILE] The $FOLDER_SRC doesn't exist, exit installation" 
	exit 1
fi

if [ -L $HOME ] && [ -e $HOME ]; then
	echo "[$HOSTNAME $CURRENT_USER FAILE] The link $HOME exist, exit installation." 
        exit 1
fi

[ ! -d $INSTALL ] && ( mkdir -p $INSTALL )

if [ ! -w $INSTALL ]; then
	echo "[$HOSTNAME $CURRENT_USER FAILE] The $INSTALL doesn't have the write permission, exit installation." 
        exit 1
fi

echo "[$HOSTNAME $CURRENT_USER INFO] Copy $FOLDER_SRC to $INSTALL"
cp -fr $FOLDER_SRC $INSTALL
echo "[$HOSTNAME $CURRENT_USER INFO] Make the link $HOME $INSTALL"
ln -s $INSTALL/$FOLDER $HOME

CONFIG_FOLDER=$ROOT_PATH"/template/"$COMPONENT"/"
CONFIG_FOLDER=`echo "$CONFIG_FOLDER" | sed 's,//,/,g'`


echo "[$HOSTNAME $CURRENT_USER INFO] config folder path: $CONFIG_FOLDER "
if [ -d $CONFIG_FOLDER ]; then
	PARAMETER_FILE=$ROOT_PATH"/conf/"$COMPONENT".properties"	
	for folders in $(find $CONFIG_FOLDER -maxdepth 1 -type d); do
		if [ ! "$CONFIG_FOLDER" = "$folders" ]; then
			echo "[$HOSTNAME $CURRENT_USER INFO] Copy the folder from $folders to $HOME"
			cp -fr $folders $HOME
		fi
	done 
	if [ -f $PARAMETER_FILE ]; then
		for file in $(find $CONFIG_FOLDER -type f); do
			echo "[$HOSTNAME $CURRENT_USER INFO] Begin replace the parameter file $PARAMETER_FILE in the configuration folder:$CONFIG_FOLDER"
			while IFS='=' read -r key value
			do
				key="$""{"$key"}"
				reallfile=$HOME/$(echo $file| sed "s@$CONFIG_FOLDER@@g" )
				echo "[$HOSTNAME $CURRENT_USER INFO] Replace the $key value $value in the file:$reallfile "
				sed -i "s@$key@$value@g" $reallfile
			done < "$PARAMETER_FILE"
		done
	fi

fi

echo "[$HOSTNAME $CURRENT_USER INFO] Install $COMPONENT environment success!"
