#!/bin/bash
if [ $# -ne 2 ]; then 
  echo "usage:"
  echo "$0 CENTRAL_IP ENCAP_TYPE"
  echo ""
  echo "example: $0 'x.x.x.2' '[vxlan|geneve|...]'"
  exit 1
fi;
CENTRAL_IP=$1 #'x.x.x.2'
ENCAP_TYPE=$2 #'vxlan'
/usr/share/openvswitch/scripts/ovn-ctl stop_controller
ovs-vsctl set Open_vSwitch . \
 external_ids:ovn-remote="tcp:$CENTRAL_IP:6642" \
 external_ids:ovn-nb="tcp:$CENTRAL_IP:6641" \
 external_ids:ovn-encap-ip="${CENTRAL_IP}" \
 external_ids:ovn-encap-type=vxlan
/usr/share/openvswitch/scripts/ovn-ctl start_controller
