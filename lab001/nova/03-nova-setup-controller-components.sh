#!/bin/bash
. common.inc.sh
yum -y install \
  openstack-nova-api openstack-nova-conductor openstack-nova-console \
  openstack-nova-novncproxy openstack-nova-scheduler

wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.1/rabbitmq-server-3.6.1-1.noarch.rpm

rpm --import https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
yum -y install rabbitmq-server-3.6.1-1.noarch.rpm

systemctl enable rabbitmq-server
systemctl start  rabbitmq-server

rabbitmqctl add_user openstack ${NOVA_RABBIT_PASS}
rabbitmqctl set_permissions -p '/' openstack '.*' '.*' '.*' 

if ! [ -f  "${NOVA_CONF}.bak" ]; then
  cp "${NOVA_CONF}" "${NOVA_CONF}.bak"
fi;

{
  cat <<EOF
[DEFAULT]
auth_strategy = keystone
my_ip = x.x.x.2
use_neutron = True
enabled_apis = osapi_compute,metadata
firewall_driver = nova.virt.libvirt.firewall.IptablesFirewallDriver
transport_url=$NOVA_RABBIT_CONN

[api_database]
connection=$NOVA_API_DB_CONN

[barbican]

[cache]

[cells]

[cinder]

[cloudpipe]

[conductor]

[cors]

[cors.subdomain]

[crypto]

[database]
connection = $NOVA_DB_CONN

[ephemeral_storage_encryption]

[glance]
api_servers=$GLANCE_ENDPOINT_URL

[guestfs]

[hyperv]

[ironic]

[key_manager]

[keystone_authtoken]
auth_uri = http://$CONTROLLER_HOST:5000
auth_url = http://$CONTROLLER_HOST:35357
memcached_servers = $CONTROLLER_HOST:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = $NOVA_DBPASS

[libvirt]

[matchmaker_redis]

[metrics]

[mks]

[neutron]

[osapi_v21]

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_messaging_zmq]

[oslo_middleware]

[oslo_policy]

[placement]

[placement_database]

[rdp]

[remote_debug]

[serial_console]

[spice]

[ssl]

[trusted_computing]

[upgrade_levels]

[vmware]

[vnc]
vncserver_listen=$CONTROLLER_IP
vncserver_proxyclient_address=$CONTROLLER_IP

[workarounds]

[wsgi]

[xenserver]

[image_file_url]

[libvirt]

[matchmaker_redis]

[xvp]




EOF
} > $NOVA_CONF


su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
systemctl enable \
  openstack-nova-api.service \
  openstack-nova-consoleauth.service \
  openstack-nova-scheduler.service \
  openstack-nova-conductor.service \
  openstack-nova-novncproxy.service

systemctl start \
  openstack-nova-api.service \
  openstack-nova-consoleauth.service \
  openstack-nova-scheduler.service \
  openstack-nova-conductor.service \
  openstack-nova-novncproxy.service

