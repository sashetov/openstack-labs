#!/bin/bash
# ovn-trace flood example
ovn-trace lsw0 'inport=="668033d2-06a4-4aaa-aca5-30cde245e478" && eth.src==52:54:00:93:05:26 && eth.dst==ff:ff:ff:ff:ff:ff'
