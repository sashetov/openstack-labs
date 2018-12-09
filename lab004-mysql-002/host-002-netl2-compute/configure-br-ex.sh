#!/bin/bash
. vars.inc
. functions.inc
neutron_conf_configure_brex
neutron_conf_configure_ifcfg_brex
stop_networking
start_networking
