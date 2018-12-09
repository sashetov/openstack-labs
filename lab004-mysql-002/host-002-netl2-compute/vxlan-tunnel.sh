#!/bin/bash
ovs-vsctl add-port br-tun vxlan0 -- set Interface vxlan0 type=vxlan options:remote_ip=x.x.x.2
ovs-vsctl add-port br-tun tepi0 -- set Interface tepi0 type=internal
ifconfig tepi0 10.0.0.20/24 up
