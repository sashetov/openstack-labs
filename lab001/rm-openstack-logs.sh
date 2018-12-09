#!/bin/bash
echo rm -f /var/log/{mysqld.log,openvswitch/*.log,httpd/keystone*.log,keystone/*.log,glance/*.log,nova/*.log,glance/*.log,neutron/*.log}
rm -f /var/log/{mysqld.log,openvswitch/*.log,httpd/keystone*.log,keystone/*.log,glance/*.log,nova/*.log,glance/*.log,neutron/*.log}
