#!/bin/bash
. vars.inc
. functions.inc

#horizon_install_rpm
#horizon_write_settings_file
systemctl restart httpd.service memcached.service
