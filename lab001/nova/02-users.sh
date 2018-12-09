#!/bin/bash
. adminrc
export NOVA_DBPASS='9b38c5cb4812ee74166b'
export NOVA_USERPASS=$NOVA_DBPASS
export CONTROLLER_HOST='mysql-001.vassilevski.com'
export NOVA_PORT=8774
export NOVA_URL=http://${CONTROLLER_HOST}:$NOVA_PORT/v2.1/%\(tenant_id\)s

openstack user create --domain default --password $NOVA_USERPASS nova
openstack role add --project service --user nova admin
openstack service create --name nova compute
openstack endpoint create --region RegionOne compute public  $NOVA_URL
openstack endpoint create --region RegionOne compute internal $NOVA_URL
openstack endpoint create --region RegionOne compute admin $NOVA_URL
