#!/bin/bash
. demorc
openstack router create router
neutron router-interface-add router selfservice
neutron router-gateway-set router provider
#neutron router-interface-delete router selfservice
#openstack router delete router
