#!/bin/bash
if [ $# -ne 1 ]; then 
  echo "usage:";
  echo "$0 path/to/conf.ini";
  echo ""
  exit 1;
fi;
conf=$1
crudini --get --list $conf | while read sec; do {
  echo "[$sec]";
  crudini --get --list $conf $sec | while read opt; do {
    echo "$opt = `crudini --get $conf $sec $opt`"; 
  }; done; 
  echo;
}; done;
