#!/bin/bash
. vars.inc
#mysqld
mariadb_clean_datadir(){
  rm -rf /var/lib/mysql
}
mariadb_install_rpms(){
  yum -y install mariadb-server
}
mariadb_enable_and_start(){
  systemctl enable mariadb
  systemctl start mariadb
}
mariadb_configure(){
  crudini --set /etc/my.cnf.d/server.cnf mysqld max_connections 500
}
mariadb_mysql_secure_install(){
  mysql --user=root <<EOF
UPDATE mysql.user SET Password=PASSWORD('${MYSQL_ROOT_PASS}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
}
mariadb_verify_client(){
  mysql -p$MYSQL_ROOT_PASS -e "show variables;"
}
mariadb_install(){
  mariadb_clean_datadir
  mariadb_install_rpms
  mariadb_enable_and_start
  mariadb_configure
  systemctl restart mariadb
  mariadb_mysql_secure_install
  mariadb_verify_client
}
#mysqld-community
mysqld_install() {
  rpm -ivh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
  yum -y install mysql-community-server
  systemctl enable mysqld
  systemctl start mysqld
  cp -f /usr/lib/systemd/system/mysqld.service /etc/systemd/system/mysqld.service
  mariadb_mysql_secure_install
  crudini --set /etc/my.cnf.d/server.cnf mysqld max_connections 500
  crudini --set /etc/my.cnf.d/server.cnf mysqld socket /var/lib/mysql/mysql.sock
  crudini --set /etc/my.cnf.d/server.cnf mysqld datadir /var/lib/mysql/data/
  crudini --set /etc/my.cnf.d/server.cnf mysqld innodb_log_group_home_dir /var/lib/mysql/logs/
  crudini --set /etc/my.cnf.d/server.cnf mysqld innodb_doublewrite 0
  crudini --set /etc/my.cnf.d/server.cnf mysqld sql_mode 'NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES'
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'SET GLOBAL max_connections=500;'
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "SHOW VARIABLES LIKE '%max_connections%';"
}
#rabbitmq-server
rabbitmq_clean_old(){
  rm -rf /var/lib/rabbitmq/
}
rabbitmq_install_rpm(){
  wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.1/rabbitmq-server-3.6.1-1.noarch.rpm
  rpm --import https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
  yum -y install rabbitmq-server-3.6.1-1.noarch.rpm
  rm -f rabbitmq-server-3.6.1-1.noarch.rpm
}
rabbitmq_enable_and_start(){
  systemctl enable rabbitmq-server
  systemctl start  rabbitmq-server
}
rabbitmq_manage_user_auth_and_permissions(){
  rabbitmqctl change_password guest $RABBIT_GUEST_PASS
  rabbitmqctl add_user nova $RABBIT_GUEST_PASS
  rabbitmqctl add_user neutron $RABBIT_GUEST_PASS
  rabbitmqctl set_permissions nova ".*" ".*" ".*"
  rabbitmqctl set_permissions neutron ".*" ".*" ".*"
}
rabbitmq_server_install(){
  rabbitmq_clean_old
  rabbitmq_install_rpm
  rabbitmq_enable_and_start
  rabbitmq_manage_user_auth_and_permissions
}
#ntpd
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
#openstack prereqs
openstack_client_install(){
  yum -y install python-openstackclient
}
openstack_prereqs(){
  #mariadb_install
  mysqld_install
  rabbitmq_server_install
  ntpd_install
  openstack_client_install
}
#keystone install funcs
keystone_db_and_grants(){
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e 'CREATE DATABASE keystone;'
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "GRANT ALL PRIVILEGES ON keystone.* to 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "GRANT ALL PRIVILEGES ON keystone.* to 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "GRANT ALL PRIVILEGES ON keystone.* to 'keystone'@'mysql-001.vassilevski.com' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "FLUSH PRIVILEGES;";
}
keystone_config(){
  keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
  chown -R keystone:keystone $KEYSTONE_LOG_DIR $KEYSTONE_SSL_DIR
  openstack-config --set $KEYSTONE_CONF signing token_format PKI
  openstack-config --set $KEYSTONE_CONF signing certfile $KEYSTONE_SIGNING_CERT
  openstack-config --set $KEYSTONE_CONF signing keyfile $KEYSTONE_SIGNING_KEY
  openstack-config --set $KEYSTONE_CONF signing ca_certs $KEYSTONE_SIGNING_CA_CERT
  openstack-config --set $KEYSTONE_CONF signing key_size 1024
  openstack-config --set $KEYSTONE_CONF signing valid_days 3650
  openstack-config --set $KEYSTONE_CONF signing ca_password None
  openstack-config --set $KEYSTONE_CONF assignment list_limit 100
}
keystone_bootstrap_db() {
  su keystone -s /bin/sh -c "keystone-manage db_sync"
  keystone-manage fernet_setup \
    --keystone-user keystone \
    --keystone-group keystone
  keystone-manage credential_setup \
    --keystone-user keystone \
    --keystone-group keystone
  keystone-manage bootstrap \
    --bootstrap-password $KEYSTONE_ADMIN_TOKEN \
    --bootstrap-username admin \
    --bootstrap-project-name admin \
    --bootstrap-role-name admin \
    --bootstrap-service-name keystone \
    --bootstrap-region-id RegionOne \
    --bootstrap-admin-url $KEYSTONE_ADMIN_URL \
    --bootstrap-public-url  $KEYSTONE_PUBLIC_URL \
    --bootstrap-internal-url $KEYSTONE_PUBLIC_URL
}
keystone_dump_authfiles(){
  [[ -z $1 ]] && PATH_ADMINRC='~/.os_admirc' || PATH_ADMINRC=$1
  [[ -z $2 ]] && PATH_USERRC='~/.os_userrc' || PATH_USERRC=$2
  {
    cat <<EOF
export OS_USERNAME=admin
export PS1="[\u@\h \W-adminrc]\$ "
export OS_USERNAME=admin
export OS_PASSWORD=$KEYSTONE_ADMIN_TOKEN
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=$KEYSTONE_ADMIN_URL
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
  } > $PATH_ADMINRC
  {
    cat <<EOF
export PS1="[\u@\h \W -userrc]\$ "
export OS_USERNAME=demo
export OS_PASSWORD=$KEYSTONE_USER_PASSWORD
export OS_PROJECT_NAME=demo
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_AUTH_URL=$KEYSTONE_PUBLIC_URL
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
  } > $PATH_USERRC
}
keystone_create_service_and_unpriv_user_data() {
  . adminrc
  openstack project create --domain default service
  openstack project create --domain default demo
  openstack user create --domain default --password ${KEYSTONE_USER_PASSWORD} demo
  openstack role create user
  openstack role add --project demo --user demo user
}
keystone_install(){
  keystone_db_and_grants
  yum install -y openstack-keystone openstack-utils openstack-selinux
  openstack-config --set $KEYSTONE_CONF sql connection $KEYSTONE_DB_CONN
  keystone_config
  yum -y install httpd mod_wsgi
  keystone_bootstrap_db
  ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
  systemctl enable httpd.service
  systemctl start httpd.service
  keystone_dump_authfiles ./adminrc ./userrc
  keystone_create_service_and_unpriv_user_data
}
# glance install funcs
glance_db_and_grants() {
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'CREATE DATABASE glance;'
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON glance.* to 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "GRANT ALL PRIVILEGES ON glance.* to 'glance'@'$CONTROLLER_HOST' IDENTIFIED BY '${GLANCE_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "GRANT ALL PRIVILEGES ON glance.* to 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "FLUSH PRIVILEGES;"
}
glance_provision_users_roles_services_endpoints()
{
  . adminrc
  openstack user create --domain default --password ${GLANCE_USERPASS} glance
  openstack role add --project service --user glance admin
  openstack service create --name glance image
  openstack endpoint create --region RegionOne image public ${GLANCE_ENDPOINT_URL}
  openstack endpoint create --region RegionOne image internal ${GLANCE_ENDPOINT_URL}
  openstack endpoint create --region RegionOne image admin ${GLANCE_ENDPOINT_URL}
}
glance_configure(){
  openstack-config --set $GLANCE_API_CONF DEFAULT sql_connection $GLANCE_DB_CONN
  openstack-config --set $GLANCE_REGISTRY_CONF DEFAULT sql_connection $GLANCE_DB_CONN
  openstack-config --set $GLANCE_API_CONF paste_deploy flavor keystone
  openstack-config --set $GLANCE_REGISTRY_CONF paste_deploy flavor keystone
  openstack-config --set $GLANCE_API_CONF  keystone_authtoken auth_url "http://$CONTROLLER_HOST:$KEYSTONE_ADMIN_PORT"
  openstack-config --set $GLANCE_API_CONF  keystone_authtoken auth_uri "http://$CONTROLLER_HOST:$KEYSTONE_PUBLIC_PORT"
  openstack-config --set $GLANCE_API_CONF  keystone_authtoken memcached_servers ${CONTROLLER_HOST}:11211
  openstack-config --set $GLANCE_API_CONF  keystone_authtoken auth_type password
  openstack-config --set $GLANCE_API_CONF  keystone_authtoken project_domain_name Default
  openstack-config --set $GLANCE_API_CONF  keystone_authtoken user_domain_name Default
  openstack-config --set $GLANCE_API_CONF  keystone_authtoken project_name service
  openstack-config --set $GLANCE_API_CONF  keystone_authtoken username glance
  openstack-config --set $GLANCE_API_CONF  keystone_authtoken password $GLANCE_USERPASS
  openstack-config --set $GLANCE_REGISTRY_CONF  keystone_authtoken auth_url "http://$CONTROLLER_HOST:$KEYSTONE_ADMIN_PORT"
  openstack-config --set $GLANCE_REGISTRY_CONF  keystone_authtoken auth_uri "http://$CONTROLLER_HOST:$KEYSTONE_PUBLIC_PORT"
  openstack-config --set $GLANCE_REGISTRY_CONF  keystone_authtoken memcached_servers ${CONTROLLER_HOST}:11211
  openstack-config --set $GLANCE_REGISTRY_CONF  keystone_authtoken auth_type password
  openstack-config --set $GLANCE_REGISTRY_CONF  keystone_authtoken project_domain_name Default
  openstack-config --set $GLANCE_REGISTRY_CONF  keystone_authtoken user_domain_name Default
  openstack-config --set $GLANCE_REGISTRY_CONF  keystone_authtoken project_name service
  openstack-config --set $GLANCE_REGISTRY_CONF  keystone_authtoken username glance
  openstack-config --set $GLANCE_REGISTRY_CONF  keystone_authtoken password $GLANCE_USERPASS
  openstack-config --set $GLANCE_API_CONF  glance_store stores file,http
  openstack-config --set $GLANCE_API_CONF  glance_store default_store file
  openstack-config --set $GLANCE_API_CONF  glance_store filesystem_store_datadir $GLANCE_DATADIR
}
glance_sync_db(){
  su -s /bin/sh -c "glance-manage db_sync" glance
}
glance_enable_and_start_services(){
  systemctl enable \
    openstack-glance-api.service \
    openstack-glance-registry.service
  systemctl start \
    openstack-glance-api.service \
    openstack-glance-registry.service
}
glance_cirros_image_add(){
  . adminrc
  wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
  openstack image create \
    "cirros" \
    --file cirros-0.3.4-x86_64-disk.img \
    --disk-format qcow2 \
    --container-format bare \
    --public
  openstack image list
  rm -f cirros-0.3.4-x86_64-disk.img
}
glance_install(){
  yum -y install openstack-glance
  glance_db_and_grants
  glance_provision_users_roles_services_endpoints
  glance_configure
  glance_sync_db
  glance_enable_and_start_services
  glance_cirros_image_add
}
#nova install funcs
nova_db_and_grants() {
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'CREATE DATABASE nova_api;'
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'CREATE DATABASE nova;'
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova_api.* to 'nova'@'localhost' IDENTIFIED BY '${NOVA_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova_api.* to 'nova'@'%' IDENTIFIED BY '${NOVA_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova_api.* to 'nova'@'$CONTROLLER_HOST' IDENTIFIED BY '${NOVA_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova.* to 'nova'@'localhost' IDENTIFIED BY '${NOVA_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova.* to 'nova'@'%' IDENTIFIED BY '${NOVA_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON nova.* to 'nova'@'$CONTROLLER_HOST' IDENTIFIED BY '${NOVA_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;";
}
nova_service_users_roles_endpoints(){
  . adminrc
  openstack user create --domain default --password $NOVA_USERPASS nova
  openstack role add --project service --user nova admin
  openstack service create --name nova compute
  openstack endpoint create --region RegionOne compute public  $NOVA_URL
  openstack endpoint create --region RegionOne compute internal $NOVA_URL
  openstack endpoint create --region RegionOne compute admin $NOVA_URL
}
nova_install_rpms_without_compute() {
  yum -y install \
    openstack-nova-api openstack-nova-conductor openstack-nova-console \
    openstack-nova-novncproxy openstack-nova-scheduler
}
nova_configure(){
  openstack-config --set $NOVA_CONF DEFAULT enabled_apis osapi_compute,metadata
  openstack-config --set $NOVA_CONF DEFAULT transport_url $NOVA_RABBIT_CONN
  openstack-config --set $NOVA_CONF DEFAULT auth_strategy keystone
  openstack-config --set $NOVA_CONF DEFAULT my_ip $CONTROLLER_IP
  openstack-config --set $NOVA_CONF DEFAULT use_neutron True
  openstack-config --set $NOVA_CONF api_database connection $NOVA_API_DB_CONN
  openstack-config --set $NOVA_CONF database connection $NOVA_DB_CONN
  openstack-config --set $NOVA_CONF keystone_authtoken auth_uri http://$CONTROLLER_HOST:5000
  openstack-config --set $NOVA_CONF keystone_authtoken auth_url http://$CONTROLLER_HOST:35357
  openstack-config --set $NOVA_CONF keystone_authtoken memcached_servers $CONTROLLER_HOST:11211
  openstack-config --set $NOVA_CONF keystone_authtoken auth_type password
  openstack-config --set $NOVA_CONF keystone_authtoken project_domain_name Default
  openstack-config --set $NOVA_CONF keystone_authtoken user_domain_name Default
  openstack-config --set $NOVA_CONF keystone_authtoken project_name service
  openstack-config --set $NOVA_CONF keystone_authtoken username nova
  openstack-config --set $NOVA_CONF keystone_authtoken password $NOVA_DBPASS
  openstack-config --set $NOVA_CONF vnc vncserver_proxyclient_address $CONTROLLER_IP
  openstack-config --set $NOVA_CONF vnc vncserver_listen $CONTROLLER_IP
  openstack-config --set $NOVA_CONF glance api_servers $GLANCE_ENDPOINT_URL
  openstack-config --set $NOVA_CONF oslo_concurrency lock_path $NOVA_LOCK_PATH
}
nova_dbs_sync(){
  su -s /bin/sh -c "nova-manage api_db sync" nova
  su -s /bin/sh -c "nova-manage db sync" nova
}
nova_enable_nocompute_services() {
  systemctl enable \
    openstack-nova-api.service \
    openstack-nova-consoleauth.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service
}
nova_start_nocompute_services(){
  systemctl start \
    openstack-nova-api.service \
    openstack-nova-consoleauth.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service

}
nova_install_rmps_compute(){
  yum -y install openstack-nova-compute
}
nova_configure_compute(){
  openstack-config --set ${NOVA_CONF} DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
  openstack-config --set ${NOVA_CONF} vnc enabled True
  openstack-config --set ${NOVA_CONF} libvirt virt_type $NOVA_VIRT_TYPE
  openstack-config --set ${NOVA_CONF} vnc enabled True
  openstack-config --set ${NOVA_CONF} vnc novncproxy_base_url "http://$CONTROLLER_IP:6080/vnc_auto.html"
}
nova_enable_compute(){
  systemctl enable \
    libvirtd.service \
    openstack-nova-compute.service
}
nova_stop_all_current_services() {
  systemctl stop openstack-nova-novncproxy.service \
    openstack-nova-conductor.service \
    openstack-nova-scheduler.service \
    openstack-nova-consoleauth.service \
    openstack-nova-api.service \
    openstack-glance-registry.service \
    openstack-glance-api.service \
    httpd.service \
    mysqld.service
    #mariadb.service
  service rabbitmq-server stop
}
nova_start_services_with_compute(){
  service rabbitmq-server start
  systemctl start libvirtd.service \
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
    #mariadb.service
}
nova_verify(){
  . adminrc
  openstack compute service list
}
nova_install() {
  nova_db_and_grants
  nova_service_users_roles_endpoints
  nova_install_rpms_without_compute
  nova_configure
  nova_dbs_sync
  nova_enable_nocompute_services
  nova_start_nocompute_services
  nova_install_rmps_compute
  nova_configure_compute
  nova_enable_compute
  nova_stop_all_current_services
  nova_start_services_with_compute
  nova_verify
}
#neutron install funcs
neutron_db_and_grants() {
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e 'CREATE DATABASE neutron;'
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON neutron.* to 'neutron'@'localhost' IDENTIFIED BY '${NEUTRON_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON neutron.* to 'neutron'@'%' IDENTIFIED BY '${NEUTRON_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON neutron.* to 'neutron'@'$CONTROLLER_HOST' IDENTIFIED BY '${NEUTRON_DBPASS}';"
  mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"
}
neutron_service_users_roles_endpoints(){
  . adminrc
  openstack user create --domain default --password ${NEUTRON_USERPASS} neutron
  openstack role add --project service --user neutron admin
  openstack service create --name neutron network
  openstack endpoint create --region RegionOne network public $NEUTRON_URL
  openstack endpoint create --region RegionOne network internal $NEUTRON_URL
  openstack endpoint create --region RegionOne network admin $NEUTRON_URL
}
neutron_rpms_install(){
  yum -y install openstack-neutron \
    openstack-neutron-ml2 \
    openstack-neutron-openvswitch \
    ebtables \
    $OVS_RPMS
  for KMOD_LOAD_CONF in  ${KMOD_LOAD_CONFS[*]}; do
    echo $OVS_KMOD>> $KMOD_LOAD_CONF
  done;
  modprobe $OVS_KMOD
}
neutron_conf_neutron_ini() {
  #neutron_conf
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
  openstack-config --set $NEUTRON_CONF nova region_name RegionOne
  openstack-config --set $NEUTRON_CONF nova auth_url http://$CONTROLLER_HOST:$KEYSTONE_ADMIN_PORT
  openstack-config --set $NEUTRON_CONF nova auth_type password
  openstack-config --set $NEUTRON_CONF nova project_domain_name Default
  openstack-config --set $NEUTRON_CONF nova project_name service
  openstack-config --set $NEUTRON_CONF nova user_domain_name Default
  openstack-config --set $NEUTRON_CONF nova username nova
  openstack-config --set $NEUTRON_CONF nova password $NOVA_USERPASS
  openstack-config --set $NEUTRON_CONF oslo_concurrency lock_path $NEUTRON_LOCK_PATH
}
neutron_conf_ml2_ini(){
  #ml2_conf
  openstack-config --set ${NEUTRON_ML2_CONF} ml2 type_drivers 'flat,vxlan'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2 tenant_network_types 'vxlan'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2 mechanism_drivers 'openvswitch,l2population'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2 extension_drivers 'port_security'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2_type_flat flat_networks '*'
  openstack-config --set ${NEUTRON_ML2_CONF} ml2_type_vxlan vni_ranges '7777:8000'
  openstack-config --set ${NEUTRON_ML2_CONF} securitygroup enable_ipset 'True'
  openstack-config --set ${NEUTRON_ML2_CONF} securitygroup firewall_driver 'neutron.agent.firewall.NoopFirewallDriver'
  openstack-config --set ${NEUTRON_ML2_CONF} securitygroup enable_security_group 'True'

}
neutron_conf_openvswitch_agent_ini(){
  #openvswitch_agent
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs integration_bridge br-int
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs tunnel_bridge br-tun
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs int_peer_patch_port patch-tun
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs tun_peer_patch_port patch-int
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs bridge_mappings "$EXTERNAL_NETWORK:$PROVIDER_BRIDGE"
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs of_interface ovs-ofctl
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs local_ip $PROVIDER_NETWORK_START_IP
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF ovs enable_tunneling True
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF agent tunnel_types vxlan
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF agent l2_population True
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
  openstack-config --set $NEUTRON_ML2_OPENVSWITCH_AGENT_CONF securitygroup enable_security_group True
}
neutron_conf_l3_agent_ini(){
  openstack-config --set $NEUTRON_L3_AGENT_CONF DEFAULT ovs_integration_bridge br-int
  openstack-config --set $NEUTRON_L3_AGENT_CONF DEFAULT interface_driver openvswitch
}
neutron_conf_dhcp_agent_ini() {
  openstack-config --set $NEUTRON_DHCP_AGENT_CONF DEFAULT ovs_integration_bridge br-int
  openstack-config --set $NEUTRON_DHCP_AGENT_CONF DEFAULT interface_driver openvswitch
  openstack-config --set $NEUTRON_DHCP_AGENT_CONF DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
  openstack-config --set $NEUTRON_DHCP_AGENT_CONF DEFAULT enable_isolated_metadata True
}
neutron_conf_metadata_agent_ini(){
  openstack-config --set $NEUTRON_METADATA_AGENT DEFAULT nova_metadata_ip $CONTROLLER_HOST
  openstack-config --set $NEUTRON_METADATA_AGENT DEFAULT metadata_proxy_shared_secret $NEUTRON_METADATA_SECRET
}
neutron_conf_nova_conf(){
  openstack-config --set ${NOVA_CONF} neutron metadata_proxy_shared_secret $NEUTRON_METADATA_SECRET
  openstack-config --set ${NOVA_CONF} neutron url $NEUTRON_URL
  openstack-config --set ${NOVA_CONF} neutron auth_url http://$CONTROLLER_HOST:$KEYSTONE_ADMIN_PORT
  openstack-config --set ${NOVA_CONF} neutron auth_type password
  openstack-config --set ${NOVA_CONF} neutron project_domain_name Default
  openstack-config --set ${NOVA_CONF} neutron user_domain_name Default
  openstack-config --set ${NOVA_CONF} neutron region_name RegionOne
  openstack-config --set ${NOVA_CONF} neutron project_name service
  openstack-config --set ${NOVA_CONF} neutron username neutron
  openstack-config --set ${NOVA_CONF} neutron password $NEUTRON_USERPASS
  openstack-config --set ${NOVA_CONF} vnc vncserver_listen $CONTROLLER_IP
  openstack-config --set ${NOVA_CONF} vnc vncserver_proxyclient_address $CONTROLLER_IP
}
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
UUID="255defd7-149d-4d83-9d5d-05f5b302b9c2"
DEVICE="$PROVIDER_BRIDGE"
IPADDR=$PROVIDER_NETWORK_START_IP
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
UUID=91218df7-2b1e-4da8-bb7c-a5efc91d1df4
DEVICE=$PROVIDER_PHY_INTERFACE
ONBOOT="yes"
TYPE="OVSPort"
DEVICETYPE="ovs"
OVS_BRIDGE="$PROVIDER_BRIDGE"
NM_CONTROLLED=no
EOF
  } > $PROVIDER_IFACE_CONF

}
neutron_enable_ml2_plugin(){
  ln -s $NEUTRON_ML2_CONF /etc/neutron/plugin.ini
}
neutron_dbsync(){
  su -s /bin/sh -c "neutron-db-manage --config-file $NEUTRON_CONF --config-file $NEUTRON_ML2_CONF upgrade head" neutron
}
neutron_enable_new_services(){
  systemctl enable neutron-server.service \
    neutron-openvswitch-agent.service \
    neutron-dhcp-agent.service \
    neutron-metadata-agent.service \
    neutron-l3-agent.service
}
neutron_stop_current_services(){
  systemctl stop openstack-nova-compute.service \
    libvirtd.service \
    openstack-nova-novncproxy.service \
    openstack-nova-conductor.service \
    openstack-nova-scheduler.service \
    openstack-nova-consoleauth.service \
    openstack-nova-api.service \
    openstack-glance-registry.service \
    openstack-glance-api.service \
    httpd.service \
    mysqld.service &&
  service rabbitmq-server stop;
}
neutron_start_all_services() {
  service rabbitmq-server start
  systemctl start \
    mysqld.service \
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
}
neutron_do_all_config_files() {
  neutron_conf_neutron_ini
  neutron_conf_ml2_ini
  neutron_conf_openvswitch_agent_ini
  neutron_conf_l3_agent_ini
  neutron_conf_dhcp_agent_ini
  neutron_conf_metadata_agent_ini
  neutron_conf_nova_conf
}
neutron_install(){
  neutron_db_and_grants
  neutron_service_users_roles_endpoints
  neutron_rpms_install
  neutron_do_all_config_files
  neutron_enable_ml2_plugin
  neutron_dbsync
  neutron_enable_new_services
  neutron_stop_current_services
  neutron_start_all_services
}
#neutron networks+router configuration
neutron_create_provider_net(){
  .adminrc
  neutron net-create --provider:network_type flat \
          --provider:physical_network $EXTERNAL_NETWORK \
          --shared $PROVIDER_NETWORK
}
neutron_create_provider_subnet(){
  . adminrc
  neutron subnet-create \
    --name $PROVIDER_SUBNET_NAME \
    --enable-dhcp=False \
    --allocation-pool start=$PROVIDER_NETWORK_START_IP,end=$PROVIDER_NETWORK_END_IP \
    --gateway=$PROVIDER_NETWORK_GW \
      $PROVIDER_NETWORK \
      $PROVIDER_NETWORK_START_IP/32

}
neutron_create_selfservice_subnet(){
  . userrc
  SUBNET_CIDR=$1
  SUBNET_START_RANGE=$2
  SUBNET_END_RANGE=$3
  SELFSERVICE_NETWORK_NAME=$4
  SUBNET_CIDR=$5
  neutron subnet-create \
    --name $SUBNET_MAME --allocation-pool $SUBNET_START_RANGE,end=$SUBNET_END_RANGE \
    --gateway=$SUBNET_GW $SELFSERVICE_NETWORK_NAME $SUBNET_CIDR
}
config_provider_selfservice_nets_and_router() {
  . userrc
  neutron_create_provider_net
  neutron_create_provider_subnet
  neutron net-create $SELFSERVICE_NETWORK
  neutron_create_selfservice_subnet $SELFSERVICE_SUBNET1_CIDR $SELFSERVICE_SUBNET2_GW $SELFSERVICE_SUBNET2_END $SELFSERVICE_NETWORK $SELFSERVICE_SUBNET1_NAME
  neutron_create_selfservice_subnet $SELFSERVICE_SUBNET2_CIDR $SELFSERVICE_SUBNET1_GW $SELFSERVICE_SUBNET1_END $SELFSERVICE_NETWORK $SELFSERVICE_SUBNET2_NAME
  openstack router create $ROUTER_NAME
  openstack router add subnet $ROUTER_NAME $SELFSERVICE_SUBNET1_NAME
  openstack router add subnet $ROUTER_NAME $SELFSERVICE_SUBNET2_NAME
  openstack router set $ROUTER_NAME --route destinaton=$PROVIDER_NETWORK_CIDR,gateway=$PROVIDER_NETWORK_GW
}
neutron_create_default_security_group() {
  . userrc
  openstack security group rule create \
    --proto icmp \
    default
  openstack security group rule create \
    --ethertype IPv6 \
    --proto ipv6-icmp \
    default
  openstack security group rule create \
    --proto tcp \
    --dst-port 22 \
    default
  openstack security group rule create \
    --ethertype IPv6 \
    --proto tcp \
    --dst-port 22 \
    default
}
neutron_create_user_keypair() {
  . userrc
  openstack keypair create \
    --public-key "~/.ssh/id_rsa.pub" \
    rootpubkey
}
neutron_create_flavor(){
  . adminrc
  ID=$1
  VCPUS=$2
  RAM=$3
  DISK=$4
  NAME=$5
  openstack flavor create \
    --id $ID \
    --vcpus $VCPUS \
    --ram $RAM \
    --disk $DISK \
    $NAME
}
neutron_create_cirros_vm(){
  . userrc
  SUBNET_ID=$1
  VM_NAME=$2
  FLAVOR=$3
  openstack server create \
    --flavor $FLAVOR \
    --image cirros \
    --nic net-id=$SUBNET_ID \
    --security-group default \
    --key-name rootpubkey \
    --wait \
    $VM_NAME &&
  echo $( openstack server show -f value -C ID $VM_NAME )
}
neutron_conf_networks_and_launch_servers() {
  . userrc
  config_provider_selfservice_nets_and_router
  SELFSERVICE_SUBNET1_ID=$( openstack subnet show -f value -C ID $SELFSERVICE_SUBNET1_NAME );
  SELFSERVICE_SUBNET2_ID=$( openstack subnet show -f value -C ID $SELFSERVICE_SUBNET2_NAME );
  neutron_create_flavor $VM_FLAVOR_ID $VM_FLAVOR_VCPUS $VM_FLAVOR_RAM_MB $VM_FLAVOR_DISK_GB $VM_FLAVOR_NAME
  neutron_create_user_keypair
  neutron_create_default_security_group
  VM1_ID=$(neutron_create_cirros_vm $SELFSERVICE_SUBNET1_ID $VM1_NAME $VM_FLAVOR_ID)
  VM2_ID=$(neutron_create_cirros_vm $SELFSERVICE_SUBNET2_ID $VM2_NAME $VM_FLAVOR_ID)
  openstack console log show $VM1_ID
  openstack console log show $VM2_ID
}
# delete functions for all network configs
neutron_delete_all_user_vms_nets_and_router() {
  . userrc
  openstack server delete $VM1_NAME --wait &&
  openstack server delete $VM2_NAME --wait
  openstack router set $ROUTER_NAME --no-route
  openstack router remove subnet $ROUTER_NAME $SELFSERVICE_SUBNET1_NAME
  openstack router remove subnet $ROUTER_NAME $SELFSERVICE_SUBNET2_NAME
  openstack port list \
    -f value -C ID \
    --router $ROUTER_NAME | while read PORT_ID; do {
      openstack router remove port $ROUTER_NAME $PORT_ID;
  }; done;
  openstack router delete router $ROUTER_NAME
  openstack subnet delete $SELFSERVICE_SUBNET1_NAME
  openstack subnet delete $SELFSERVICE_SUBNET2_NAME
  openstack network delete $SELFSERVICE_NETWORK
}
neutron_delete_all_admin_networks(){
  . adminrc
  openstack subnet delete  $PROVIDER_VIRT_SUBNET_NAME
  openstack network delete $PROVIDER_NETWORK
}
neutron_delete_all_nets_and_router(){
  neutron_delete_all_user_vms_nets_and_router
  neutron_delete_all_admin_networks
}
#drop + recreate all dbs and grants
drop_all_openstack_dbs() {
  ./stop-openstack-services.sh
  systemctl start mysqld #mariadb
  DBS="nova nova_api neutron keystone glance";
  for DBNAME in ${DBS[*]}; do
    mysql -h localhost -u root -p"${MYSQL_ROOT_PASS}"  -e "DROP DATABASE $DBNAME;"
  done;
}
create_all_openstack_dbs_and_grants(){
  keystone_db_and_grants
  glance_db_and_grants
  nova_db_and_grants
  neutron_db_and_grants
}
# start stop functions
start_openstack_services(){
  service rabbitmq-server start &&
  systemctl start memcached.service \
    mysqld.service \
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
    neutron-l3-agent.service
}
stop_openstack_services(){
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
    mysqld.service \
    memcached.service &&
  service rabbitmq-server stop
}
stop_system_networking_completely(){
  stop_openstack_services
  killall neutron-openvswitch-agent
  /etc/sysconfig/network-scripts/ifdown-ovs ifcfg-br-ex
  /etc/sysconfig/network-scripts/ifdown-eth ifcfg-eno1
  systemctl stop ovs-vswitchd.service ovsdb-server.service
  service network stop
}
restart_system_networking(){
  stop_system_networking_completely
  systemctl start neutron-ovs-cleanup.service &&
  systemctl start ovs-vswitchd.service ovsdb-server.service &&
  systemctl restart network
}
restart_networking_completely_and_launch_openstack(){
  restart_system_networking &&
  start_openstack_services
}

