#!/bin/bash
. common.inc.sh
#rm -f ~/.my.cnf
#/usr/bin/mysqladmin -u root password "${pass}"
#/usr/bin/mysqladmin -u root -p"${pass}" -h mysql-001.vassilevski.com password "${pass}"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'CREATE DATABASE keystone;'
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON keystone.* to 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "GRANT ALL PRIVILEGES ON keystone.* to 'keystone'@'mysql-001.vassilevski.com' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "GRANT ALL PRIVILEGES ON keystone.* to 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
