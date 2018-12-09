#!/bin/bash
zfs create -o mountpoint=none spool/mysql
zfs set primarycache=metadata spool/mysql
zfs set atime=off spool/mysql
zfs set sync=disabled spool/mysql
zfs create -o mountpoint=none spool/mysql/innodb_data
zfs set recordsize=16k spool/mysql/innodb_data
zfs create -o mountpoint=none spool/mysql/innodb_logs
zfs set recordsize=128k spool/mysql/innodb_logs
zfs set zfs:zfs_prefetch_disable=1 spool
zfs set zfs:zfs_nocacheflush=1 spool
zpool export spool
zpool import -d /dev/disk/by-id spool
mkdir /var/lib/mysql /var/lib/mysql/logs /var/lib/mysql/data
zfs set mountpoint=/var/lib/mysql/data spool/mysql/innodb_data
zfs set mountpoint=/var/lib/mysql/logs spool/mysql/innodb_logs
zpool export spool
zpool import -d /dev/disk/by-id spool
