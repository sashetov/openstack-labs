#!/bin/bash
. common.inc.sh
yum -y install openstack-glance
if ! [ -f  "${GLANCE_API_CONF}.bak" ]; then
  cp "${GLANCE_API_CONF}" "${GLANCE_API_CONF}.bak"
fi;

{
  cat <<EOF
[DEFAULT]

[cors]

[cors.subdomain]

[database]
connection = $DB_CONNECTION_STR_GLANCE

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images

[image_format]

[keystone_authtoken]
auth_url = http://$CONTROLLER_HOST:$HTTPD_KEYSTONE_PUBLIC_PORT
auth_url = http://$CONTROLLER_HOST:$HTTPD_KEYSTONE_ADMIN_PORT
memcached_servers = ${CONTROLLER_HOST}:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = $GLANCE_USERPASS

[matchmaker_redis]

[oslo_concurrency]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_messaging_zmq]

[oslo_middleware]

[oslo_policy]

[paste_deploy]
flavor = keystone

[profiler]

[store_type_location_strategy]

[task]

[taskflow_executor]

EOF
} > ${GLANCE_API_CONF}

if ! [ -f  "${GLANCE_REGISTRY_CONF}.bak" ]; then
  cp "${GLANCE_REGISTRY_CONF}" "${GLANCE_REGISTRY_CONF}.bak"
fi;

{
  cat <<EOF
[database]
connection = $DB_CONNECTION_STR_GLANCE

[keystone_authtoken]
auth_uri = http://$CONTROLLER_HOST:$HTTPD_KEYSTONE_PUBLIC_PORT
auth_url = http://$CONTROLLER_HOST:$HTTPD_KEYSTONE_ADMIN_PORT
memcached_servers = ${CONTROLLER_HOST}:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = $GLANCE_USERPASS

[matchmaker_redis]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_messaging_zmq]

[oslo_policy]

[paste_deploy]
flavor = keystone

[profiler]


EOF
} > ${GLANCE_REGISTRY_CONF}

su -s /bin/sh -c "glance-manage db_sync" glance
systemctl enable \
  openstack-glance-api.service \
  openstack-glance-registry.service
systemctl start \
  openstack-glance-api.service \
  openstack-glance-registry.service
