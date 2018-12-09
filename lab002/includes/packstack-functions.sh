#!/bin/bash
. includes/logger.sh
download_src() {
  . includes/repo-branch-vars.inc.sh
  git clone $GITHUB_URL $PACKSTACK_REPO_DIR &&
  cd $PACKSTACK_REPO_DIR &&
  git checkout $CURRENT_STABLE_BRANCH
}
ensure_gem_homedir() {
  if [ ! -d $GEM_HOME ]; then 
    mkdir -p $GEM_HOME;
  fi;
}
install_depends () {
  . includes/repo-branch-vars.inc.sh
  . includes/gem-vars.inc.sh
  # install packstack egg
  cd $PACKSTACK_REPO_DIR &&
  python setup.py install &&
  # install needed gems(){
  gem install $REQUIRED_GEMS
}
run_puppetfile () {
  . includes/gem-vars-inc.sh
  sudo -E r10k Puppetfile install -v
}

