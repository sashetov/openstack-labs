#!/bin/bash
#. common.inc.sh
. adminrc
export DNS_RESOLVER='d.d.d.1'
export PROVIDER_NETWORK_START_IP='x.x.x.2'
export PROVIDER_NETWORK_END_IP='185.119.172.242'
export PROVIDER_NETWORK_GW='x.x.x.1'
export PROVIDER_NETWORK_CIDR='x.x.x.2/25'
openstack network create \
  --share --provider-physical-network provider \
  --provider-network-type flat provider
openstack subnet create --network provider \
  --allocation-pool start=$PROVIDER_NETWORK_START_IP,end=$PROVIDER_NETWORK_END_IP \
  --dns-nameserver $DNS_RESOLVER --gateway $PROVIDER_NETWORK_GW \
  --subnet-range $PROVIDER_NETWORK_CIDR provider
