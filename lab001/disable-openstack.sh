#!/bin/bash
SERVICES='openvswitch.service'\
' ovn-controller-vtep.service'\
' ovn-controller.service'\
' ovn-northd.service'\
' ovs-vswitchd.service'\
' ovsdb-server.service'\
' mysqld.service'\
' httpd.service'\
' openstack-glance-api.service'\
' openstack-glance-registry.service'\
' openstack-nova-api.service'\
' openstack-nova-consoleauth.service'\
' openstack-nova-scheduler.service'\
' openstack-nova-conductor.service'\
' openstack-nova-novncproxy.service'\
' libvirtd.service'\
' openstack-nova-compute.service'\
' neutron-server.service'\
' neutron-linuxbridge-agent.service'\
' neutron-dhcp-agent.service'\
' neutron-metadata-agent.service'\
' neutron-openvswitch-agent.service'\
' neutron-l3-agent.service'\
' rabbitmq-server.service';
MODULES_LOAD_FILES='/etc/modules-load.d/openvswitch.conf'\
' /usr/lib/modules-load.d/openvswitch.conf';
MODULES_NAMES='openvswitch'
SYS_NETCONFIG_PATH='/etc/sysconfig/network-scripts'
CONF_BACKUP_DIR='/root/openstack/conf'
IFACE_CONFIGS=`echo $SYS_NETCONFIG_PATH/ifcfg-{br-ex,br-int,br-tun,eno1}`
IFACE_BACKUPS="${CONF_BACKUP_DIR}${SYS_NETCONFIG_PATH}/ifcfg-eno1.bak"
echo "$0" &&
echo "01. stopping all related services" &&
echo "systemctl stop $SERVICES" &&
systemctl stop $SERVICES &&
echo "02. DISABLING all related services" &&
echo "systemctl disable $SERVICES" &&
systemctl disable $SERVICES &&
echo "03. removing load modules configs" &&
echo "rm -f $MODULES_LOAD_FILES" &&
rm -f $MODULES_LOAD_FILES &&
echo "04. removing modules from kernel" &&
echo "modprobe -r $MODULES_NAMES" &&
modprobe -r $MODULES_NAMES &&
echo "05. stopping network" &&
echo "service network stop" &&
service network start &&
echo "06. removing unneeded bridge and iface configs" &&
echo "rm -f $IFACE_CONFIGS" &&
rm -f $IFACE_CONFIGS &&
echo "07. replacing eno1 iface config with original" &&
echo "cp $IFACE_BACKUPS $SYS_NETCONFIG_PATH/ifcfg-eno1" &&
cp $IFACE_BACKUPS "$SYS_NETCONFIG_PATH/ifcfg-eno1" &&
echo "08. starting network" &&
echo "service network start" &&
service network start &&
echo "09. testing network connectivity with world" &&
echo "ping -W 1 -c 3 8.8.8.8 1>/dev/null 2>/dev/null" &&
ping -W 1 -c 3 8.8.8.8 1>/dev/null 2>/dev/null &&
echo -e "\n\n $0 completed successfuly" ||
echo -e "ERROR: \nsomething went wrong  $? , see last run step"
