#!/bin/bash
disable_nfs_services(){
 systemctl disable nfs-server.service \
   nfs.service \
   rpcbind.socket \
   nfs-idmapd.service \
   nfs-mountd.service \
   rpc-statd.service \
   rpcbind.service \
   rpcbind.socket
}

