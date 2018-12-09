#!/bin/bash
. common.inc.sh
yum -y install openstack-neutron openstack-neutron-ml2 \
  openstack-neutron-openvswitch \
  ebtables

if ! [ -f  "${NEUTRON_CONF}.bak" ]; then
  cp "${NEUTRON_CONF}" "${NEUTRON_CONF}.bak"
fi;
{
  cat <<EOF
[DEFAULT]
auth_strategy = keystone
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
transport_url = $NEUTRON_RABBIT_CONN

[agent]

[cors]

[cors.subdomain]

[database]
connection = $NEUTRON_DB_CONN

[keystone_authtoken]
auth_uri = http://$CONTROLLER_HOST:$HTTPD_KEYSTONE_PUBLIC_PORT
auth_url = http://$CONTROLLER_HOST:$HTTPD_KEYSTONE_ADMIN_PORT
memcached_servers = ${CONTROLLER_HOST}:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = $NEUTRON_USERPASS

[matchmaker_redis]

[nova]
region_name = RegionOne
auth_url = http://$CONTROLLER_HOST:$HTTPD_KEYSTONE_ADMIN_PORT
auth_type = password
project_domain_name = Default
project_name = service
user_domain_name = Default
username = nova
password = $NOVA_USERPASS

[oslo_concurrency]
lock_path = /var/lib/neutron/tmp

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_messaging_zmq]

[oslo_middleware]

[oslo_policy]

[qos]

[quotas]

[ssl]



EOF
} > $NEUTRON_CONF


if ! [ -f  "${NEUTRON_ML2_CONF}.bak" ]; then
  cp "${NEUTRON_ML2_CONF}" "${NEUTRON_ML2_CONF}.bak"
fi;
{
  cat <<EOF
[DEFAULT]

[ml2]
type_drivers = flat,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security

[ml2_type_flat]
flat_networks = *

[ml2_type_geneve]

[ml2_type_gre]

[ml2_type_vlan]

[ml2_type_vxlan]
flat_networks = *
vni_ranges = 1:1000

[securitygroup]
enable_ipset = True

EOF
} > $NEUTRON_ML2_CONF

if ! [ -f  "${NEUTRON_ML2_OPENVSWITCH_AGENT_CONF}.bak" ]; then
  cp "${NEUTRON_ML2_OPENVSWITCH_AGENT_CONF}" "${NEUTRON_ML2_OPENVSWITCH_AGENT_CONF}.bak"
fi;

{
  cat <<EOF
[DEFAULT]

[agent]
tunnel_types = vxlan
l2_population = True


[ovs]
integration_bridge = br-int
tunnel_bridge = br-tun
int_peer_patch_port = patch-tun
tun_peer_patch_port = patch-int
bridge_mappings = provider:br-ex
of_interface = ovs-ofctl
local_ip = 10.1.1.128

[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_security_group = true
enable_ipset = True

EOF
} > ${NEUTRON_ML2_OPENVSWITCH_AGENT_CONF}

if ! [ -f  "${NEUTRON_L3_AGENT_CONF}.bak" ]; then
  cp "${NEUTRON_L3_AGENT_CONF}" "${NEUTRON_L3_AGENT_CONF}.bak"
fi;

{
  cat <<EOF
[DEFAULT]
ovs_integration_bridge = br-int
interface_driver = openvswitch

[AGENT]

EOF
} > ${NEUTRON_L3_AGENT_CONF}

if ! [ -f  "${NEUTRON_DHCP_AGENT_CONF}.bak" ]; then
  cp "${NEUTRON_DHCP_AGENT_CONF}" "${NEUTRON_DHCP_AGENT_CONF}.bak"
fi;

{
  cat <<EOF
[DEFAULT]
ovs_integration_bridge = br-int
interface_driver = openvswitch
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True

[AGENT]

EOF
} > $NEUTRON_DHCP_AGENT_CONF

if ! [ -f  "${NEUTRON_METADATA_AGENT}.bak" ]; then
  cp "${NEUTRON_METADATA_AGENT}" "${NEUTRON_METADATA_AGENT}.bak"
fi;

{
cat <<EOF
[DEFAULT]
nova_metadata_ip = $CONTROLLER_HOST
metadata_proxy_shared_secret = $NEUTRON_METADATA_SECRET

[AGENT]

[cache]
EOF
} > ${NEUTRON_METADATA_AGENT}

crudini --set ${NOVA_CONF} neutron metadata_proxy_shared_secret $NEUTRON_METADATA_SECRET
crudini --set ${NOVA_CONF} neutron url $NEUTRON_URL
crudini --set ${NOVA_CONF} neutron auth_url http://$CONTROLLER_HOST:$HTTPD_KEYSTONE_ADMIN_PORT
crudini --set ${NOVA_CONF} neutron auth_type password
crudini --set ${NOVA_CONF} neutron project_domain_name Default
crudini --set ${NOVA_CONF} neutron user_domain_name Default
crudini --set ${NOVA_CONF} neutron region_name RegionOne
crudini --set ${NOVA_CONF} neutron project_name service
crudini --set ${NOVA_CONF} neutron username neutron
crudini --set ${NOVA_CONF} neutron password $NEUTRON_USERPASS
crudini --set ${NOVA_CONF} vnc vncserver_listen $CONTROLLER_IP
crudini --set ${NOVA_CONF} vnc vncserver_proxyclient_address $CONTROLLER_IP

ln -s $NEUTRON_ML2_CONF /etc/neutron/plugin.ini

su -s /bin/sh -c \
  "neutron-db-manage --config-file $NEUTRON_CONF --config-file $NEUTRON_ML2_CONF upgrade head" neutron

systemctl restart openstack-nova-api.service

systemctl enable neutron-server.service \
  neutron-openvswitch-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service

systemctl start neutron-server.service \
  neutron-openvswitch-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service

systemctl enable neutron-l3-agent.service
systemctl start neutron-l3-agent.service

