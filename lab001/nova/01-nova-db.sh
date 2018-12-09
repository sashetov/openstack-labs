#!/bin/bash
. common.inc.sh
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'CREATE DATABASE nova_api;'
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'CREATE DATABASE nova;'
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova_api.* to 'nova'@'localhost' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova_api.* to 'nova'@'%' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova_api.* to 'nova'@'$CONTROLLER_HOST' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova.* to 'nova'@'localhost' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova.* to 'nova'@'%' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova.* to 'nova'@'$CONTROLLER_HOST' IDENTIFIED BY '${NOVA_DBPASS}';"
