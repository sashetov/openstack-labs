#!/bin/bash
. demorc
openstack keypair create --public-key ~/.ssh/id_rsa.pub rootpubkey
