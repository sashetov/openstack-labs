#!/bin/bash
if [ $# -ne 1 ]; then 
  echo "usage:"
  echo "$0 PORT_ID"
  exit 1
fi;
. demorc
port_id=$1;
neutron port-update --no-security-groups  $port_id
neutron port-update $port_id --port-security-enabled=False
neutron port-show $port_id
