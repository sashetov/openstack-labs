#!/bin/bash
export MIN_DIR="/root/openstack/logs/`date +%Y-%m-%d'/'%H%M`"
export WARN_ERRS_DIR="$MIN_DIR/warnings-errors"
mkdir -p $WARN_ERRS_DIR
cp -a /var/log/{openvswitch/*.log,nova/*.log,neutron/*.log} $MIN_DIR 2>/dev/null
egrep -i 'warning|error' $MIN_DIR/*.log  2>/dev/null | sort -k2,2 -d > $WARN_ERRS_DIR/log
echo ${WARN_ERRS_DIR}/log ${MIN_DIR}/*
