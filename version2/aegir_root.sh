#!/bin/sh
version=0.2-36

echo " `basename $0` $version"

#Instructions from http://community.aegirproject.org/installing/manual

#this script is only for redhat based systems
#this script has only been tested on CentOS 5 & 6 systems

if ! [ -s /etc/redhat-release ] #assuming this is sufficient
then 
	echo " ERROR: This is _NOT_ a Redhat based distribution. Quitting"
	exit 1
fi
echo "بسم الله الرحمن الرحيم"

#variables
export WEBHOME=/var/aegir

if [ -s /etc/centos-release ] 
then
        os=centos
        grep 6 /etc/centos-release > /dev/null && version=6 || version=5
else
        os=rhel
        grep 6 /etc/redhat-release > /dev/null && version=6 || version=5
fi

if [ "$version" -eq "5" ] 
then
	echo " ERROR: `basename $0` is only for $os 6"
	exit 8
fi

interface=eth0

yum -y install ftp://ftp.muug.mb.ca/mirror/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm

[ "$version" -eq "5" ] && yum -y erase php php-common
[ "$version" -eq "5" ] && yum -y install httpd postfix sudo unzip mysql-server php53 php53-pdo php53-process php53-mysql git php53-mbstring bzr cvs php53-gd php53-xml || yum -y install httpd postfix sudo unzip mysql-server php php-pdo php-process php-mysql git php-mbstring bzr cvs php-gd php-xml php-drush-drush

echo " INFO: Raising PHP's memory limit to 512M"
sed -i 's/^memory_limit = .*$/memory_limit = 512M/g' /etc/php.ini 
export city=`cat /etc/sysconfig/clock | grep ZONE | cut -d= -f2 | sed -s 's/"//g'`
sed -i 's+;date.timezone =+date.timezone = '$city' +g' /etc/php.ini

echo " INFO: Restarting httpd and mysqld"
service httpd restart
service mysqld restart

chkconfig httpd on
chkconfig mysqld on

mysql -uroot -e 'show databases;' > /dev/null 2>&1
if [ $? -eq 0 ]
then 
	/usr/bin/mysql_secure_installation
else
	echo " INFO: MySQL previous configured. Skipping"
fi

echo " INFO: Disabling SElinux"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
echo 0 >/selinux/enforce
setenforce 0

echo " INFO: AEgir User creation"
useradd --home-dir $WEBHOME aegir
gpasswd -a aegir apache
chmod -R 755 $WEBHOME

! [ -d $WEBHOME ] && mkdir $WEBHOME 
chown aegir.apache $WEBHOME

grep aegir /etc/sudoers > /dev/null
if ! [ $? -eq 0 ]
then
        echo "aegir ALL=NOPASSWD: /usr/sbin/apachectl" >> /etc/sudoers
        sed -i 's/^Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers
fi

if ! [ -d /etc/httpd/conf.d/aegir.conf ]
then 
        ln -s $WEBHOME/config/apache.conf /etc/httpd/conf.d/aegir.conf
fi

#dns configuration - add to /etc/hosts
hostfile(){
echo " INFO: Adding `hostname` entry to /etc/hosts"
ip=`ifconfig $interface | grep -w inet | awk '{print $2}' | cut -d: -f2`
echo "$ip\t`hostname`" >> /etc/hosts
}

resolveip `hostname` > /dev/null
if ! [ $? -eq 0 ]
then
	grep `hostname` /etc/hosts > /dev/null
	if ! [ $? -eq 0 ]
	then
		hostfile
	else
		echo " ERROR: `hostname` does not resolve even though it is /etc/hosts"
	fi
fi


drush_upgrade(){ #upgrade drush to latest
pear upgrade
pear channel-discover pear.drush.org
pear install drush/drush
}

drush_upgrade &
