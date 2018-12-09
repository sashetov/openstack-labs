#!/bin/bash
 . vars.inc
yum -y install rabbitmq-server
systemctl start rabbitmq-server.service
systemctl enable rabbitmq-server.service
rabbitmqctl change_password guest $RABBIT_GUEST_PASS
rabbitmqctl add_user cinder $RABBIT_GUEST_PASS
rabbitmqctl add_user nova $RABBIT_GUEST_PASS
rabbitmqctl add_user neutron $RABBIT_GUEST_PASS
rabbitmqctl add_user heat $RABBIT_GUEST_PASS
rabbitmqctl add_user glance $RABBIT_GUEST_PASS
rabbitmqctl add_user ceilometer $RABBIT_GUEST_PASS
rabbitmqctl set_permissions cinder ".*" ".*" ".*"
rabbitmqctl set_permissions nova ".*" ".*" ".*"
rabbitmqctl set_permissions neutron ".*" ".*" ".*"
rabbitmqctl set_permissions heat ".*" ".*" ".*"
rabbitmqctl set_permissions glance ".*" ".*" ".*"
rabbitmqctl set_permissions ceilometer ".*" ".*" ".*"
