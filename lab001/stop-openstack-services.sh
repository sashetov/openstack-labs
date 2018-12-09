#!/bin/bash
systemctl stop neutron-l3-agent.service \
  neutron-metadata-agent.service \
  neutron-dhcp-agent.service \
  neutron-openvswitch-agent.service \
  neutron-server.service \
  openstack-nova-compute.service \
  libvirtd.service \
  openstack-nova-novncproxy.service \
  openstack-nova-conductor.service \
  openstack-nova-scheduler.service \
  openstack-nova-consoleauth.service \
  openstack-nova-api.service \
  openstack-glance-registry.service \
  openstack-glance-api.service \
  httpd.service \
  mysqld.service

#  neutron-linuxbridge-agent.service \
