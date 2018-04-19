# Instructions

This package setup the **NEW** full cluster environment, not only work for Hadoop, it also can easy adapt to other cluster software installation if you make the configuration as this instruction.

The script only run in the **Master Node**, the **Data Node** will setup by master ssh remote installation.

## Environment

The environment required can execute the bash command, and had been test in those linux systems as below.

* Ubuntu 
* Centos
 
 
## Pre-installation

###SSH (Secure Shell)
You will be root user in the system, and setup the SSH(Secure Shell) protocol, enable the root SSH access in the **all cluster servers**.

```
vi /etc/ssh/sshd_config
```
Comment out the following line and add the new line

```
#PermitRootLogin without-password
PermitRootLogin yes
```
Restart SSH

```
service ssh reload
```
###Expect
You need install the **Expect** software in the **Master Node**, the script work on ubuntu system as the root user.

```
apt-get update
apt-get install expect
```
## Configuration

Propose current path is script path, edit the files under `conf` folder depend on your cluster environment.
###1. Parameters
Edit the file: `conf\parameters`

```
vi conf\parameters
```

```
username=hadoop
password=pass
usergroup=hadoop
install_path=/tmp/shell2/
install_components=jvm,hadoop
jvm_user=root
jvm_folder=java-8-oracle
jvm_install=/usr/lib/jvm
jvm_home=/usr/lib/jvm/java
hadoop_user=hadoop
hadoop_folder=hadoop-2.8.3
hadoop_home=/node/hadoop
hadoop_install=/node
```
Usually the component (ex: Hadoop) require the normal use to isolate the root user. 
####user
Script can create a new user for components, you need set the **username,passord,usergroup**
```
username=hadoop
password=pass
usergroup=hadoop
```

####install_path
These scripts copy to different servers, the path decide which path will be saved in the servers.
```
install_path=/tmp/shell2/
```

####install_components
This parameter indicate which component will be installed in the server, seperate by comma.
```
install_components=jvm,hadoop
```


####component_conf
You need set the parameters as below description.

Name  | Common
------------- | -------------
component#_user  | The component's user(install,run)
component#_folder  | The component's name in the folder `package`
component#_home  | The component's home folder(It is link to assign the setup folder)
component#_install  | The component's setup folder, make sure user has read/write privilege in this install path

Example as blow:

```
hadoop_user=hadoop
hadoop_folder=hadoop-2.8.3
hadoop_home=/node/hadoop
hadoop_install=/node
```


###2. env

Edit the file: `vi conf\env`

```
export XXX=/usr/lib/hive
```
Sometime you need define some specified enviroment parameters. This env file update the file `~/.bashrc`

###3. ${componet}.properties

Every component can supply the specified properties, #key# #value# pair define replacement template parameter and value

The *template* can reference into <mark>template</mark>  part.

If you have hadoop component, the template file hadoop.xml in the hadoop template folder `template/hadoop/hadoop.xml`  examples:

```
<name>fs.defaultFS</name>
<value>${fs.defaultFS}<value>
```
You can add the new line 
```
fs.defaultFS=\node\
``` in the hdfs.properties (hdfs is component name)

At the last, the `hadoop.xml` file will change as below.
 
```
<name>fs.defaultFS</name>
<value>\node\<value>
```

###4. Datanode

Edit the file: `conf\datanode`

```
vi conf\datanode
```
Add the data nodes except the master node server **hostname**,**ip address**,**root**,**password**, split by space for each elements.

Some operators need logon the system as root user, you need configuration the root user(or root privilege user) and password. 

Example as below:

```
datanode1 192.168.121.145 root pass
datanode2 192.168.121.146 root pass
```


###5. Namenode

Edit the file: `conf\namenode`

```
vi conf\namenode
```

Add the master node server(this server) **hostname**,**ip address**,**root**,**password**, split by space for each elements.

Also this require the root user

Example as below:

```
namenode 192.168.121.147 root pass
```

## Package
Script doesn't support `yum` or `apt-get` install the component. Need put original installation package in the folder `package`. If you want to modify the configuration file, go to part `template`

For examples:

`package/java-8-oracle`

Of cause you also set `conf\parameters`, assign the value to component_folder EX: `jvm_folder=java-8-oracle`

## Template

If the component has speicial configuration for `package`, you can customeize the files in the folder `template`. Put the modification files into `package` in the correspond package path. The script will overwrite the files in the installation folder.

Some replacement words can define format as `${key}`, the exchange value be set in the file `component.properties` as above.

## bin 

All bash scripts exist in `bin` folder, simple prompt as below.

`install_component.sh` install component script

`config_#component#.sh` config component script if you want

## How to install

 `./install.sh` in the root path
 

Enjoy the one-click cluster installation script. Hope can help you. Any requirement is welcome <raintung.li@gmail.com>

