#!/bin/bash
. demorc
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default
