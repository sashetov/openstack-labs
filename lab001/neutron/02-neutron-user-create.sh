#!/bin/bash
. adminrc
export CONTROLLER_HOST='mysql-001.vassilevski.com'
export NEUTRON_DBPASS='1fa19933e40c3b495043'
export NEUTRON_USERPASS=$NEUTRON_DBPASS
export NEUTRON_API_PORT=9696
export NEUTRON_URL=http://${CONTROLLER_HOST}:$NEUTRON_API_PORT
openstack user create --domain default --password ${NEUTRON_USERPASS} neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron network
openstack endpoint create --region RegionOne network public $NEUTRON_URL
openstack endpoint create --region RegionOne network internal $NEUTRON_URL
openstack endpoint create --region RegionOne network admin $NEUTRON_URL
