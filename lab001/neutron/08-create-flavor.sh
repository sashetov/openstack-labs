#!/bin/bash
. adminrc
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
