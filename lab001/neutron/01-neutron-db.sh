#!/bin/bash
. common.inc.sh
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'CREATE DATABASE neutron;'
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e \
  "GRANT ALL PRIVILEGES ON neutron.* to 'neutron'@'localhost' IDENTIFIED BY '${NEUTRON_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e \
  "GRANT ALL PRIVILEGES ON neutron.* to 'neutron'@'%' IDENTIFIED BY '${NEUTRON_DBPASS}';"
mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e \
  "GRANT ALL PRIVILEGES ON neutron.* to 'neutron'@'$CONTROLLER_HOST' IDENTIFIED BY '${NEUTRON_DBPASS}';"
