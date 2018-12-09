#!/bin/bash
systemctl start mysqld.service \
  httpd.service \
  openstack-glance-api.service \
  openstack-glance-registry.service \
  openstack-nova-api.service \
  openstack-nova-consoleauth.service \
  openstack-nova-scheduler.service \
  openstack-nova-conductor.service \
  openstack-nova-novncproxy.service \
  libvirtd.service \
  openstack-nova-compute.service \
  neutron-server.service \
  neutron-dhcp-agent.service \
  neutron-metadata-agent.service \
  neutron-openvswitch-agent.service \
  neutron-l3-agent.service;

#neutron-linuxbridge-agent.service \
