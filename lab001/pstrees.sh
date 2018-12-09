#!/bin/bash
export proc_comms=''\
'ovsdb-server ovs-vswitchd '\
' /usr/sbin/httpd /usr/bin/mysqld_safe'\
' /usr/bin/epmd /usr/sbin/rabbitmq-server'\
' /usr/bin/glance-api /usr/bin/glance-registry'\
' /usr/bin/neutron-server /usr/bin/neutron-dhcp-agent /usr/bin/neutron-metadata-agent /bin/neutron-ns-metadata-proxy /usr/bin/neutron-l3-agent /usr/bin/neutron-linuxbridge-agent /usr/bin/neutron-openvswitch-agent'\
' dnsmasq'\
' /usr/sbin/libvirtd /usr/sbin/virtlogd /usr/lib/systemd/systemd-machined'\
' /usr/bin/nova-api /usr/bin/nova-consoleauth /bin/privsep-helper /usr/bin/nova-scheduler /usr/bin/nova-conductor /usr/bin/nova-novncproxy /usr/bin/nova-compute'\
' /usr/libexec/qemu-kvm';

ppid () {
  ps -p ${1:-$$} -o ppid= | sed -r 's/\s//g';
}
pstree_pid(){
  #pstree -nplaAscu $1;
  pstree -nplaAcu $1;
}
print_pid_cmdline(){
  pid=$1
  printf "$pid `cat /proc/$pid/cmdline`\n";
}
printf_array() {
  declare -a array=("${!1}")
  let i=0;
  let n=${#array[@]}
  printf "[";
  for el in "${array[@]}"; do {
    let i++;
    printf "'${el}'";
    if [[ $i == $n ]]; then
      printf "]\n"
    else
      printf ", "
    fi;
  }; done;
}
array_contains(){
  #starts from 1, returns in bash functions are >0 numbers
  let pos=1;
  declare -a arr=("${!1}")
  el="${@:2}"
  for arr_el in "${arr[@]}"; do {
    if [[ "${arr_el}" == "${el}" ]]; then 
      # matched, return position
      return $pos;
    fi;
    let pos++
  }; done;
  # no match, so return 0 "position"
  return 0;
}
print_pstrees(){
  proc_comms=$*
  for proc_comm in $proc_comms; do {
    pids=`pgrep -f $proc_comm`
    pids_arr=(`echo $pids`);
    echo proc_comm:$proc_comm
    echo pids:$pids
    for pid in "${pids_arr[@]}"; do {
      ppid=`ppid $pid`;
      array_contains pids_arr[@] $ppid && {
        #not found (pos 0) - do a pstree for this pid
        pstree_pid $pid;
        echo;
      } \
      || {
        # found at returned position
        let pos=$?
        let index=$(( $pos - 1 ))
      };
    }; done;
    echo;
  }; done;
}

print_pstrees $proc_comms
