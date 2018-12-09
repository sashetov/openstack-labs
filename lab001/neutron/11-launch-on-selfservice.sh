#!/bin/bash
. demorc
export SELFSERVICE_NET_ID='93b81ea6-0b5b-4f34-a293-c3bb3180fdb3'
openstack server create --flavor m1.nano --image cirros --nic net-id="$SELFSERVICE_NET_ID" --security-group default --key-name rootpubkey selfservice-instance
openstack console url show selfservice-instance
