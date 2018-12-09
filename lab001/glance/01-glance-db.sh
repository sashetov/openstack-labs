#!/bin/bash
. common.inc.sh
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'CREATE DATABASE glance;'
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON glance.* to 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "GRANT ALL PRIVILEGES ON glance.* to 'glance'@'mysql-001.vassilevski.com' IDENTIFIED BY '${GLANCE_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "GRANT ALL PRIVILEGES ON glance.* to 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';"
