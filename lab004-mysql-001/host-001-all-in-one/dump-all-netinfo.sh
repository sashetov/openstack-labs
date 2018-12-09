#!/bin/bash
. functions.inc
. vars.inc
add_snooper_interface(){
  BR_TO_SNOOP=$1
  MIRROR_NAME='snooper'
  ip link add name snooper0 type dummy
  ip link set dev snooper0 up
  ovs-vsctl add-port $BR_TO_SNOOP snooper0
  ovs-vsctl -- set Bridge $BR_TO_SNOOP mirrors=@m  \
    -- --id=@snooper0 get Port snooper0  \
    -- --id=@patch-tun get Port patch-tun \
    -- --id=@m create Mirror name=$MIRROR_NAME \
    select-dst-port=@patch-tun select-src-port=@patch-tun \
    output-port=@snooper0 select_all=1
}
