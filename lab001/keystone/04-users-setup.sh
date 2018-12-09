#!/bin/bash
. adminrc
export USER_PASSWORD=43aefd2898f8612a0614
openstack project create --domain default service
openstack project create --domain default demo
openstack user create --domain default --password ${USER_PASSWORD} demo
openstack role create user
openstack role add --project demo --user demo user
