#!/bin/bash
. common.inc.sh
yum -y remove MariaDB-server  MariaDB-common
rpm -ivh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
yum -y install mysql-community-server
systemctl enable mysqld
systemctl start mysqld
