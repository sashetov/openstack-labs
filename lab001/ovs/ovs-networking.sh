#!/bin/bash
if [ $# -ne 7 ]; then 
  echo "usage:"
  echo "$0 IP_EX NETMASK_EX GATEWAY_EX BRINT_IP BRINT_NETMASK REMOTE_IP ENCAP_TYPE"
  echo ""
  echo "ENCAP_TYPE: gre|vxlan"
  echo ""
  echo "example: $0 'x.x.x.2' '255.255.255.128' 'x.x.x.1' '10.1.1.2' '255.255.255.0' 'x.x.x.3' '[gre|vxlan]'"
  exit 1
fi;

IP_EX=$1         #'x.x.x.2'
NETMASK_EX=$2    #'255.255.255.128'
GATEWAY_EX=$3    #'x.x.x.1'
BRINT_IP=$4      #'10.1.1.2'
BRINT_NETMASK=$5 #'255.255.255.0'
REMOTE_IP=$6     #'x.x.x.3'
ENCAP_TYPE=$7    #'gre|vxlan'

if [ $ENCAP_TYPE != 'gre' ] && [ $ENCAP_TYPE != 'vxlan' ]; then
  echo "bad ENCAP_TYPE"
  exit 2
fi;

IFNAME='eno1'  # external interface name ( atm single nic only )
BR_EX='br-ex'   # external bridge
BR_INT='br-int' # integration bridge
ovs-vsctl add-br "${BR_EX}"
#ovs-vsctl add-br "${BR_INT}" 
ovs-vsctl add-port "${BR_EX}" "${IFNAME}"
ifconfig "${IFNAME}" 0 && ifconfig "${BR_EX}" "${IP_EX}" netmask "${BRINT_NETMASK}"
#ifconfig "${BR_INT}" "${BRINT_IP}" netmask "${BRINT_NETMASK}"

if [ $ENCAP_TYPE == 'gre' ]; then
  PORT_NAME='gre1'
#  ovs-vsctl add-port "${BR_INT}" "${PORT_NAME}" -- set interface "${PORT_NAME}" type="${ENCAP_TYPE}" options:remote_ip="${REMOTE_IP}"
else
  PORT_NAME='vx1'
#  ovs-vsctl add-port "${BR_INT}" "${PORT_NAME}" -- set interface "${PORT_NAME}" type="${ENCAP_TYPE}" options:remote_ip="${REMOTE_IP}"
fi;

ip r add default via "${GATEWAY_EX}" 
