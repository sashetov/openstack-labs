#!/bin/bash
. includes/packstack-functions.sh
download_src  &&
ensure_gem_homedir &&
install_depends &&
run_puppetfile logger
