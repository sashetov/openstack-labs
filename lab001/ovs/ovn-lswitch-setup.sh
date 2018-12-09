#!/bin/bash
if [ $# -ne 2 ]; then 
  echo "usage:"
  echo "$0 LOGSWITCH_NAME OVN_IFACE"
  echo ""
  echo "example: $0 'lsw0' 'vnet0'"
  exit 1
fi;
LOGSWITCH_NAME=$1 #lsw0
OVN_IFACE=$2      #'vnet0'
echo ovs-vsctl get interface "${OVN_IFACE}" external_ids:iface-id
PORT_NAME=`ovs-vsctl get interface "${OVN_IFACE}" external_ids:iface-id | sed s/\"//g`
MAC_ADDR=`ovs-vsctl get interface vnet0 external_ids:attached-mac | sed s/\"//g`
echo ovn-nbctl ls-add "${LOGSWITCH_NAME}"
#ovn-nbctl ls-add "${LOGSWITCH_NAME}"
echo ovn-nbctl lsp-add "${LOGSWITCH_NAME}" "${PORT_NAME}" 
#ovn-nbctl lsp-add "${LOGSWITCH_NAME}" "${PORT_NAME}" 
echo ovn-nbctl lsp-set-addresses "${PORT_NAME}" "${MAC_ADDR}"
