#!/bin/bash
. vars.inc
# rpms cleanup
ovs_rpms_cleanup(){
  yum -y remove python-openvswitch-2.5.0-2.el7.noarch \
      openvswitch-ovn-docker-2.6.1-1.el7.centos.x86_64 \
      openvswitch-devel-2.6.1-1.el7.centos.x86_64 \
      openvswitch-ovn-host-2.6.1-1.el7.centos.x86_64 \
      openvswitch-ovn-common-2.6.1-1.el7.centos.x86_64 \
      openvswitch-ovn-vtep-2.6.1-1.el7.centos.x86_64
}
mariadb_rpms_cleanup(){
  yum -y remove mariadb, MariaDB-common
  sed -i 's/enabled=1/enabled=0/g'  /etc/yum.repos.d/mariadb.repo
}
#prereq install/config
mysql_community_repo_install(){
  rpm -ivh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
}
openvswitch_and_kmod_install(){
  yum -y install openvswitch-2.6.1-1.el7.centos.x86_64 openvswitch-kmod-2.6.1-1.el7.centos.x86_64
  for KMOD_LOAD_CONF in  ${KMOD_LOAD_CONFS[*]}; do
    echo $OVS_KMOD>> $KMOD_LOAD_CONF
  done;
  modprobe $OVS_KMOD
}
setup_sysctl_vars(){
  sysctl -w net.ipv4.conf.all.forwarding 1
  sysctl -w net.ipv6.conf.all.forwarding 1
  sysctl -w net.ipv4.ip_forward 1
  sysctl -w net.ipv4.conf.default.rp_filter 0
  sysctl -w net.ipv4.conf.all.rp_filter 0
  {
    echo <<EOF
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0
EOF
} > /etc/sysctl.d/00-forwarding.conf
  sysctl -w net.bridge.bridge-nf-call-arptables 1
  sysctl -w net.bridge.bridge-nf-call-ip6tables 1
  sysctl -w net.bridge.bridge-nf-call-iptables 1
  {
    echo <<EOF
net.bridge.bridge-nf-call-arptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
EOF
} > /etc/sysctl.d/01-bridge-netfilter.conf
}
enable_ovs_daemons(){
  systemctl enable ovs-vswitchd.service ovsdb-server.service
}
ntpd_install_rpms(){
  yum -y install ntp ntpdate
}
ntpd_enable_and_start(){
  systemctl enable ntpd
  systemctl start ntpd
}
ntpd_install(){
  ntpd_install_rpms
  ntpd_enable_and_start
}
rabbitmq_install_rpm(){
  wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.1/rabbitmq-server-3.6.1-1.noarch.rpm
  rpm --import https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
  yum -y install rabbitmq-server-3.6.1-1.noarch.rpm
  rm -f rabbitmq-server-3.6.1-1.noarch.rpm
}
install_openstack_utils_and_openstack_client(){
  yum -y install openstack-utils python-openstackclient
}
#nova-compute install/configure 
install_nova_services_compute_host(){
    yum -y install openstack-nova-compute
}
config_nova_computehost(){
  openstack-config --set ${NOVA_CONF} DEFAULT enabled_apis osapi_compute,metadata
  openstack-config --set ${NOVA_CONF} DEFAULT transport_url $NOVA_RABBIT_CONN
  openstack-config --set ${NOVA_CONF} DEFAULT auth_strategy keystone
  openstack-config --set ${NOVA_CONF} DEFAULT my_ip $COMPUTE_IP
  openstack-config --set ${NOVA_CONF} DEFAULT use_neutron True
  openstack-config --set ${NOVA_CONF} DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
  openstack-config --set ${NOVA_CONF} api_database connection $NOVA_API_DB_CONN
  openstack-config --set ${NOVA_CONF} database connection $NOVA_DB_CONN
  openstack-config --set ${NOVA_CONF} keystone_authtoken auth_uri http://$CONTROLLER_HOST:5000
  openstack-config --set ${NOVA_CONF} keystone_authtoken auth_url http://$CONTROLLER_HOST:35357
  openstack-config --set ${NOVA_CONF} keystone_authtoken memcached_servers $CONTROLLER_HOST:11211
  openstack-config --set ${NOVA_CONF} keystone_authtoken auth_type password
  openstack-config --set ${NOVA_CONF} keystone_authtoken project_domain_name Default
  openstack-config --set ${NOVA_CONF} keystone_authtoken user_domain_name Default
  openstack-config --set ${NOVA_CONF} keystone_authtoken project_name service
  openstack-config --set ${NOVA_CONF} keystone_authtoken username nova
  openstack-config --set ${NOVA_CONF} keystone_authtoken password $NOVA_DBPASS
  openstack-config --set ${NOVA_CONF} glance api_servers $GLANCE_ENDPOINT_URL
  openstack-config --set ${NOVA_CONF} oslo_concurrency lock_path $NOVA_LOCK_PATH
  openstack-config --set ${NOVA_CONF} libvirt virt_type $NOVA_VIRT_TYPE
  openstack-config --set ${NOVA_CONF} vnc enabled True
  openstack-config --set ${NOVA_CONF} vnc vncserver_proxyclient_address $COMPUTE_IP
  openstack-config --set ${NOVA_CONF} vnc vncserver_listen $COMPUTE_IP
  openstack-config --set ${NOVA_CONF} vnc novncproxy_base_url "http://$CONTROLLER_HOST:6080/vnc_auto.html"
}
create_compute_endpoints_in_region2(){
  . adminrc
  openstack endpoint create --region Region2 compute public  $NOVA_URL
  openstack endpoint create --region Region2 compute internal $NOVA_URL
  openstack endpoint create --region Region2 compute admin $NOVA_URL
}
enable_libvirtd_nova_compute(){
  systemctl enable \
    libvirtd \
    openstack-nova-compute.service
}
start_libvirtd_nova_compute(){
  systemctl start libvirtd openstack-nova-compute.service
}
#neutron install/configure funcs
create_neutron_endpoints_region2(){
  . adminrc
  openstack user create --domain default --password ${NEUTRON_USERPASS} neutron
  openstack role add --project service --user neutron admin
  openstack service create --name neutron network
  openstack endpoint create --region Region2 network public $NEUTRON_URL
  openstack endpoint create --region Region2 network internal $NEUTRON_URL
  openstack endpoint create --region Region2 network admin $NEUTRON_URL
}
install_neutron_l2_rpms(){
  yum -y install openstack-neutron \
   openstack-neutron-ml2 \
   openstack-neutron-openvswitch \
   ebtables
}
configure_neutron_conf_compute_host(){
  openstack-config --set $NEUTRON_CONF DEFAULT auth_strategy keystone
  openstack-config --set $NEUTRON_CONF DEFAULT core_plugin ml2
  openstack-config --set $NEUTRON_CONF DEFAULT service_plugins router
  openstack-config --set $NEUTRON_CONF DEFAULT allow_overlapping_ips True
  openstack-config --set $NEUTRON_CONF DEFAULT notify_nova_on_port_status_changes True
  openstack-config --set $NEUTRON_CONF DEFAULT notify_nova_on_port_data_changes True
  openstack-config --set $NEUTRON_CONF DEFAULT transport_url $NEUTRON_RABBIT_CONN
  openstack-config --set $NEUTRON_CONF database connection $NEUTRON_DB_CONN
  openstack-config --set $NEUTRON_CONF keystone_authtoken auth_uri http://$CONTROLLER_HOST:$KEYSTONE_PUBLIC_PORT
  openstack-config --set $NEUTRON_CONF keystone_authtoken auth_url http://$CONTROLLER_HOST:$KEYSTONE_ADMIN_PORT
  openstack-config --set $NEUTRON_CONF keystone_authtoken memcached_servers ${CONTROLLER_HOST}:11211
  openstack-config --set $NEUTRON_CONF keystone_authtoken auth_type password
  openstack-config --set $NEUTRON_CONF keystone_authtoken project_domain_name Default
  openstack-config --set $NEUTRON_CONF keystone_authtoken user_domain_name Default
  openstack-config --set $NEUTRON_CONF keystone_authtoken project_name service
  openstack-config --set $NEUTRON_CONF keystone_authtoken username neutron
  openstack-config --set $NEUTRON_CONF keystone_authtoken password $NEUTRON_USERPASS
  openstack-config --set $NEUTRON_CONF nova region_name Region2
  openstack-config --set $NEUTRON_CONF nova auth_url http://$CONTROLLER_HOST:$KEYSTONE_ADMIN_PORT
  openstack-config --set $NEUTRON_CONF nova auth_type password
  openstack-config --set $NEUTRON_CONF nova project_domain_name Default
  openstack-config --set $NEUTRON_CONF nova project_name service
  openstack-config --set $NEUTRON_CONF nova user_domain_name Default
  openstack-config --set $NEUTRON_CONF nova username nova
  openstack-config --set $NEUTRON_CONF nova password $NOVA_USERPASS
  openstack-config --set $NEUTRON_CONF oslo_concurrency lock_path $NEUTRON_LOCK_PATH
}
configure_neutron_ml2_conf_compute_host(){
  openstack-config --set ${NEUTRON_ML2_CONF} ml2 type_drivers 'flat,vxlan'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2 tenant_network_types 'vxlan'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2 mechanism_drivers 'openvswitch,l2population'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2 extension_drivers 'port_security'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2_type_flat flat_networks '*'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2_type_vxlan vni_ranges '7777:8000'
  openstack-config --set ${NEUTRON_ML2_CONF} securitygroup enable_ipset True
  openstack-config --set ${NEUTRON_ML2_CONF} securitygroup firewall_driver 'nova.virt.firewall.NoopFirewallDriver'
  openstack-config --set ${NEUTRON_ML2_CONF} securitygroup enable_security_group True
}
configure_neutron_ml2_ovs_agent_conf(){
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF agent tunnel_types vxlan
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF agent l2_population  false
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF agent vxlan_udp_port 4789
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF agent arp_responder  True
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs integration_bridge br-int
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs tunnel_bridge br-tun
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs int_peer_patch_port patch-tun
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs tun_peer_patch_port patch-int
  #openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs bridge_mappings "$PROVIDER_NETWORK:$PROVIDER_BRIDGE"
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs of_interface ovs-ofctl
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs local_ip $LOCAL_IP2_VXLAN
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs enable_tunneling True
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF securitygroup enable_security_group True
}
configure_neutron_dhcp_agent_conf(){
  openstack-config --set $NEUTRON_DHCP_AGENT_CONF DEFAULT ovs_integration_bridge br-int
  openstack-config --set $NEUTRON_DHCP_AGENT_CONF DEFAULT interface_driver openvswitch
  openstack-config --set $NEUTRON_DHCP_AGENT_CONF DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
  openstack-config --set $NEUTRON_DHCP_AGENT_CONF DEFAULT enable_isolated_metadata True
}
configure_neutron_metadata_agent_conf(){
  openstack-config --set $NEUTRON_METADATA_AGENT DEFAULT nova_metadata_ip $CONTROLLER_HOST
  openstack-config --set $NEUTRON_METADATA_AGENT DEFAULT metadata_proxy_shared_secret $NEUTRON_METADATA_SECRET
}
configure_nova_conf_neutron(){
  openstack-config --set ${NOVA_CONF} neutron metadata_proxy_shared_secret $NEUTRON_METADATA_SECRET
  openstack-config --set ${NOVA_CONF} neutron url $NEUTRON_URL
  openstack-config --set ${NOVA_CONF} neutron auth_url http://$CONTROLLER_HOST:$KEYSTONE_ADMIN_PORT
  openstack-config --set ${NOVA_CONF} neutron auth_type password
  openstack-config --set ${NOVA_CONF} neutron project_domain_name Default
  openstack-config --set ${NOVA_CONF} neutron user_domain_name Default
  openstack-config --set ${NOVA_CONF} neutron region_name Region2
  openstack-config --set ${NOVA_CONF} neutron project_name service
  openstack-config --set ${NOVA_CONF} neutron username neutron
  openstack-config --set ${NOVA_CONF} neutron password $NEUTRON_USERPASS
  openstack-config --set ${NOVA_CONF} vnc vncserver_listen $CONTROLLER_IP
  openstack-config --set ${NOVA_CONF} vnc vncserver_proxyclient_address $CONTROLLER_IP
}
link_neutron_ml2_plugin(){
  ln -s $NEUTRON_ML2_CONF /etc/neutron/plugin.ini
}
enable_ovsdb_ovsvswitch_neutron_ovs_agent_neutron_server(){
  systemctl enable neutron-server.service \
    neutron-openvswitch-agent.service \
  systemctl enable ovsdb-server ovs-vswitchd
}
#start/stop services
start_ovs_services(){
  systemctl start ovsdb-server ovs-vswitchd
}
stop_ovs_services(){
  systemctl stop ovsdb-server ovs-vswitchd
}
start_libvirt_nova_neutron_services(){
  systemctl start \
    libvirtd.service \
    openstack-nova-compute.service \
    neutron-server.service \
    neutron-openvswitch-agent.service
}
stop_libvirt_nova_neutron_services(){
  systemctl stop \
    neutron-openvswitch-agent.service \
    neutron-server.service \
    openstack-nova-compute.service \
    libvirtd.service
}
#start/stop everything networking related
start_networking(){
  start_ovs_services
  service network start
  start_libvirt_nova_neutron_services
}
stop_networking(){
  stop_libvirt_nova_neutron_services
  service network stop
  stop_ovs_services
}
# configure br-ex bridge
neutron_conf_configure_brex(){
  ovs-vsctl add-br "${PROVIDER_BRIDGE}"
  ovs-vsctl add-port "${PROVIDER_BRIDGE}" "${PROVIDER_PHY_INTERFACE}"
  ifconfig "${PROVIDER_PHY_INTERFACE}" 0 && ifconfig "${PROVIDER_BRIDGE}" "${CONTROLLER_IP}" netmask "${PROVIDER_NETMASK}"
  ip r add default via "${PROVIDER_NETWORK_GW}"
}
neutron_conf_configure_ifcfg_brex(){
  {
    cat <<EOF
TYPE="Ethernet"
NAME="$PROVIDER_BRIDGE"
UUID="70defabb-ec41-4b9c-9c95-36444bb7dfdf"
DEVICE="$PROVIDER_BRIDGE"
IPADDR=$COMPUTE_IP
PREFIX=$PROVIDER_PREFIX
GATEWAY=$PROVIDER_NETWORK_GW
DNS1=$DNS_RESOLVER
DNS2=$DNS_RESOLVER2
BOOTPROTO="none"
DEFROUTE="yes"
ONBOOT="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="no"
IPV6_AUTOCONF="no"
IPV6_DEFROUTE="no"
IPV6_PEERDNS="no"
IPV6_PEERROUTES="no"
IPV6_PRIVACY="no"
IPV6_FAILURE_FATAL="no"
NM_CONTROLLED=no
EOF
  } > $PROVIDER_BR_CONF

  {
    cat <<EOF
TYPE="Ethernet"
BOOTPROTO="none"
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="no"
IPV6_AUTOCONF="no"
IPV6_DEFROUTE="no"
IPV6_FAILURE_FATAL="no"
NAME="$PROVIDER_PHY_INTERFACE"
UUID=b1199cd9-ec77-4338-a212-aa5fd1cdfebe
DEVICE=$PROVIDER_PHY_INTERFACE
ONBOOT="yes"
TYPE="OVSPort"
DEVICETYPE="ovs"
OVS_BRIDGE="$PROVIDER_BRIDGE"
NM_CONTROLLED=no
EOF
  } > $PROVIDER_IFACE_CONF

}
neutron_get_rid_of_ovs_br_ex_master(){
  rm -f $PROVIDER_BR_CONF
  {
    cat <<EOF
UUID=b1199cd9-ec77-4338-a212-aa5fd1cdfebe
DEVICE=$PROVIDER_PHY_INTERFACE
ONBOOT=yes
BOOTPROTO=static
NM_CONTROLLED=no
TYPE=Ethernet
DNS2=$DNS_RESOLVER
DNS1=$DNS_RESOLVER
IPADDR=$COMPUTE_IP
GATEWAY=$PROVIDER_NETWORK_GW
NETMASK=$PROVIDER_NETMASK
BOOTPROTO=static
IPV6INIT=yes
EOF
  } > $PROVIDER_IFACE_CONF
  ovs-vsctl del-port "${PROVIDER_BRIDGE}" "${PROVIDER_PHY_INTERFACE}"
  ovs-vsctl del-br "${PROVIDER_BRIDGE}"
}
neutron_conf_revert_to_ifcfg_eno1(){
  ip a add "${COMPUTE_IP}/${PROVIDER_PREFIX}" dev "${PROVIDER_PHY_INTERFACE}"
  ip r add default via $PROVIDER_NETWORK_GW dev "${PROVIDER_PHY_INTERFACE}"
  systemctl network restart
}
