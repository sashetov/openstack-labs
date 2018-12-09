#!/bin/bash
TS=`date +%s`
DUMPS_DIR=$(readlink -f ./notes/tcpdumps/);
NEW_PATH_BASEDIR=$(readlink -f "./tcpdumps_renamed/")/$TS;
 nohup sudo tcpdump -i eno1 \
   -n -v 'tcp port 22 or (icmp[icmptype] = icmp-echoreply) or (icmp[icmptype] =icmp-echo)' > $DUMPS_DIR/eno1/$TS &
 nohup sudo tcpdump -i tap2582bb1a-4f \
   -n -v 'icmp[icmptype] = icmp-echoreply or icmp[icmptype] =icmp-echo' > $DUMPS_DIR/tap2582bb1a-4f/$TS &
 nohup ip netns exec qrouter-4d7b0c9b-9ed6-4e4b-9a3d-1e2eca25349b sudo tcpdump -i qr-2e39d198-16 \
   -n -v 'icmp[icmptype] = icmp-echoreply or icmp[icmptype] =icmp-echo' > $DUMPS_DIR/qrouter/qr2subnet/$TS &
 nohup ip netns exec qrouter-4d7b0c9b-9ed6-4e4b-9a3d-1e2eca25349b sudo tcpdump -i qr-8f512736-11 \
   -n -v 'icmp[icmptype] = icmp-echoreply or icmp[icmptype] =icmp-echo' > $DUMPS_DIR/qrouter/qr1subnet/$TS &
 nohup ip netns exec qrouter-4d7b0c9b-9ed6-4e4b-9a3d-1e2eca25349b sudo tcpdump -i qg-a6bbc680-f0 \
   -n -v 'icmp[icmptype] = icmp-echoreply or icmp[icmptype] =icmp-echo' > $DUMPS_DIR/qrouter/qg/$TS &
 nohup ip netns exec qdhcp-99890d45-5e0b-4520-9093-2c0501e6fd24 sudo tcpdump -i tapabd6765f-3e \
   -n -v 'icmp[icmptype] = icmp-echoreply or icmp[icmptype] =icmp-echo' > $DUMPS_DIR/qdhcp/tapabd6765f-3e/$TS &
echo when ready to stop tcpdump press enter
read
sudo killall tcpdump -9
mkdir $NEW_PATH_BASEDIR
echo made $NEW_PATH_BASEDIR
echo moving dumps to $NEW_PATH_BASEDIR:
find $DUMPS_DIR -type f -name $TS | while read DUMP_PATH; do {
 DIRNAME=$(basename $(dirname $DUMP_PATH) );
 NEW_PATH="${NEW_PATH_BASEDIR}/${DIRNAME}"
 echo mv "$DUMP_PATH" "$NEW_PATH"
 mv "$DUMP_PATH" "$NEW_PATH"
} done;
