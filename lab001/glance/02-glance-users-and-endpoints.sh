#!/bin/bash
. adminrc
CONTROLLER_HOST='mysql-001.vassilevski.com'
GLANCE_USERPASS='2d8f57a8769790e7d14c'
GLANCE_ENDPOINT_PORT=9292
GLANCE_ENDPOINT_URL="http://${CONTROLLER_HOST}:${GLANCE_ENDPOINT_PORT}"
openstack user create \
  --domain default \
  --password ${GLANCE_USERPASS} \
    glance
openstack role add \
  --project service \
  --user glance \
    admin
openstack service create \
  --name glance \
    image
openstack endpoint create \
  --region RegionOne \
    image public ${GLANCE_ENDPOINT_URL}
openstack endpoint create \
  --region RegionOne \
    image internal ${GLANCE_ENDPOINT_URL}
openstack endpoint create \
  --region RegionOne \
    image admin ${GLANCE_ENDPOINT_URL}
