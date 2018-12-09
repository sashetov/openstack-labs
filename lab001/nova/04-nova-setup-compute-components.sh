#!/bin/bash
. common.inc.sh
yum -y install openstack-nova-compute

crudini --set ${NOVA_CONF} DEFAULT my_ip $NOVA_MY_IP
crudini --set ${NOVA_CONF} vnc enabled True
crudini --set ${NOVA_CONF} vnc vncserver_listen 0.0.0.0
crudini --set ${NOVA_CONF} vnc vncserver_proxyclient_address $NOVA_MY_IP
crudini --set ${NOVA_CONF} vnc novncproxy_base_url "http://$NOVA_MY_IP:6080/vnc_auto.html"
crudini --set ${NOVA_CONF} libvirt virt_type $NOVA_VIRT_TYPE

systemctl enable \
  libvirtd.service \
  openstack-nova-compute.service

systemctl stop openstack-nova-novncproxy.service \
  openstack-nova-conductor.service \
  openstack-nova-scheduler.service \
  openstack-nova-consoleauth.service \
  openstack-nova-api.service \
  openstack-glance-registry.service \
  openstack-glance-api.service \
  httpd.service \
  mysqld.service

systemctl start  libvirtd.service \
  openstack-nova-compute.service \
  openstack-nova-novncproxy.service \
  openstack-nova-conductor.service \
  openstack-nova-scheduler.service \
  openstack-nova-consoleauth.service \
  openstack-nova-api.service \
  openstack-glance-registry.service \
  openstack-glance-api.service \
  httpd.service \
  mysqld.service
