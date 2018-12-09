#!/bin/bash
. common.inc.sh
yum -y install \
  openstack-keystone \
  httpd mod_wsgi \
  openstack-utils \
  python-openstackclient

if ! [ -f  "${KEYSTONE_CONF}.bak" ]; then
  cp "${KEYSTONE_CONF}" "${KEYSTONE_CONF}.bak"
fi;
{
  cat <<EOF
# /etc/keystone/keystone.conf
[assignment]

[auth]

[cache]

[catalog]

[cors]

[cors.subdomain]

[credential]

[database]
connection = ${DB_CONNECTION_STR_KEYSTONE}

[domain_config]

[endpoint_filter]

[endpoint_policy]

[eventlet_server]

[federation]

[fernet_tokens]

[identity]

[identity_mapping]

[kvs]

[ldap]

[matchmaker_redis]

[memcache]

[oauth1]

[os_inherit]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_messaging_zmq]

[oslo_middleware]

[oslo_policy]

[paste_deploy]

[policy]

[profiler]

[resource]

[revoke]

[role]

[saml]

[security_compliance]

[shadow_users]

[signing]

[token]
provider = fernet

[tokenless_auth]

[trust]


EOF
} > ${KEYSTONE_CONF}

if ! [ -f  "${KEYSTONE_PASTEINI_CONF}" ]; then
  cp "${KEYSTONE_PASTEINI_CONF}" "${KEYSTONE_PASTEINI_CONF}.bak"
fi;
{
  cat <<EOF
[filter:debug]
use = egg:oslo.middleware#debug

[filter:request_id]
use = egg:oslo.middleware#request_id

[filter:build_auth_context]
use = egg:keystone#build_auth_context

[filter:token_auth]
use = egg:keystone#token_auth

[filter:admin_token_auth]
use = egg:keystone#admin_token_auth

[filter:json_body]
use = egg:keystone#json_body

[filter:cors]
use = egg:oslo.middleware#cors
oslo_config_project = keystone

[filter:http_proxy_to_wsgi]
use = egg:oslo.middleware#http_proxy_to_wsgi

[filter:ec2_extension]
use = egg:keystone#ec2_extension

[filter:ec2_extension_v3]
use = egg:keystone#ec2_extension_v3

[filter:s3_extension]
use = egg:keystone#s3_extension

[filter:url_normalize]
use = egg:keystone#url_normalize

[filter:sizelimit]
use = egg:oslo.middleware#sizelimit

[filter:osprofiler]
use = egg:osprofiler#osprofiler

[app:public_service]
use = egg:keystone#public_service

[app:service_v3]
use = egg:keystone#service_v3

[app:admin_service]
use = egg:keystone#admin_service

[pipeline:public_api]
#pipeline = cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id admin_token_auth build_auth_context token_auth json_body ec2_extension public_service
pipeline = cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id build_auth_context token_auth json_body ec2_extension public_service

[pipeline:admin_api]
#pipeline = cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id admin_token_auth build_auth_context token_auth json_body ec2_extension s3_extension admin_service
pipeline = cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id build_auth_context token_auth json_body ec2_extension s3_extension admin_service

[pipeline:api_v3]
#pipeline = cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id admin_token_auth build_auth_context token_auth json_body ec2_extension_v3 s3_extension service_v3
pipeline = cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id build_auth_context token_auth json_body ec2_extension_v3 s3_extension service_v3

[app:public_version_service]
use = egg:keystone#public_version_service

[app:admin_version_service]
use = egg:keystone#admin_version_service

[pipeline:public_version_api]
pipeline = cors sizelimit osprofiler url_normalize public_version_service

[pipeline:admin_version_api]
pipeline = cors sizelimit osprofiler url_normalize admin_version_service

[composite:main]
use = egg:Paste#urlmap
/v2.0 = public_api
/v3 = api_v3
/ = public_version_api

[composite:admin]
use = egg:Paste#urlmap
/v2.0 = admin_api
/v3 = api_v3
/ = admin_version_api
EOF
} > ${KEYSTONE_PASTEINI_CONF}
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup \
  --keystone-user keystone \
  --keystone-group keystone
keystone-manage credential_setup \
  --keystone-user keystone \
  --keystone-group keystone
keystone-manage bootstrap \
  --bootstrap-password $ADMIN_TOKEN \
  --bootstrap-admin-url $OS_URL \
  --bootstrap-internal-url $OS_URL \
  --bootstrap-public-url $PUBLIC_URL \
  --bootstrap-region-id RegionOne
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service
systemctl start httpd.service
