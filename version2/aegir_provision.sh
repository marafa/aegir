#!/bin/sh
version=0.3

#the below line enables bash debugging
#set -x
#trap read debug

#Instructions from http://community.aegirproject.org/installing/manual

#this script is only for redhat based systems
#this script has only been tested on CentOS 5 & 6 systems

export aegir_ver=6.x-2.0-rc4
export WEBHOME=/var/aegir
export HOME=$WEBHOME
export DRUPAL_VER=6.x

#the following is the fqdn of the aegir front end
export AEGIR_HOST=`hostname`
export AEGIR_DB_PASS=password
export EMAIL=root@`hostname`

echo " `basename $0` $version"

###alias
grep vi $HOME/.bashrc > /dev/null
if ! [ $? -eq 0 ]
then
cat >> $HOME/.bashrc << EOF
alias vi=vim
alias grep="grep --colour=auto"
EOF
fi

. $HOME/.bashrc

cd $HOME

echo " INFO: Installing drupal module : provision"
drush -y dl provision-$aegir_ver 

if [ "$aegir_ver" == "6.x-2.0-rc4" ]                                             
then                                                                             
	sed -i 's,https://drupal,http://drupal,g' $HOME/.drush/provision/aegir.ma
fi

echo  " INFO: Running hostmaster install"
drush -y hostmaster-install $AEGIR_HOST --aegir_db_pass=$AEGIR_DB_PASS --client_email=$EMAIL

ln -s $HOME/hostmaster* hostmaster

#prepare crontab
echo " INFO: Updating crontab"
crontab -l | grep up > /dev/null 2>&1
if ! [ $? -eq 0 ]
then
	crontab -l > /tmp/cron.aegir
	echo "0 3 * * * /usr/bin/drush -y @hostmaster up" >> /tmp/cron.aegir
	echo "29 * * * * /usr/bin/drush -y @hostmaster cron" >> /tmp/cron.aegir
	echo "45 1 * * * /usr/bin/drush -y @sites up" >> /tmp/cron.aegir
	crontab /tmp/cron.aegir
	rm -rf /tmp/cron.aegir
fi

echo "************************************************************************"
echo " INFO: Updating Drupal installation"
#enable the update module
drush -y @hostmaster en update

#do the update
drush -y @hostmaster up

echo "************************************************************************"
echo " INFO: Installation complete. Please read email for $EMAIL to continue"
echo "************************************************************************"
