#!/bin/bash
. vars.inc
neutron_create_cirros_vm(){
  . userrc 
  NET_ID=$1 
  VM_NAME=$2
  FLAVOR=$3
  openstack server create \
    --flavor $FLAVOR \
    --image cirros \
    --nic net-id=$NET_ID \
    --security-group default \
    --key-name $USER_KEYPAIR_NAME \
    --wait \
  $VM_NAME 1>&2
  echo $( openstack server show -f value -c id $VM_NAME );
}

FLAVOR='0'
NET_ID='584d9ef6-3673-4cd5-beb9-87b3158d953a'
VM_NAME="vm004"

neutron_create_cirros_vm $NET_ID $VM_NAME $FLAVOR
