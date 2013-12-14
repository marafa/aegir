#!/bin/sh
### run to allow selinux to function properly
setenforce 1
sed -i 's/SELINUX=disabled/SELINUX=enforcing/g' /etc/sysconfig/selinux
echo 1 >/selinux/enforce
semanage fcontext -a -t httpd_config_t "/var/aegir/config/server_master/apache(/.*)?"
semanage fcontext -a -t httpd_sys_content_t "/var/aegir/hostmaster\.*"
semanage fcontext -a -t httpd_config_t "/var/aegir/config/server_master/apache\.conf"
restorecon -R -v -F /var/aegir/
