#!/bin/bash
. demorc
export DNS_RESOLVER='d.d.d.1'
export SELFSERVICE_NETWORK_GATEWAY='10.1.1.1'
export SELFSERVICE_NETWORK_CIDR='10.1.1.1/24'
openstack network create selfservice
openstack subnet create \
  --network selfservice \
  --dns-nameserver $DNS_RESOLVER \
  --gateway $SELFSERVICE_NETWORK_GATEWAY \
  --subnet-range $SELFSERVICE_NETWORK_CIDR selfservice
