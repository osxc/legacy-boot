if [ -z "${OSXC_REPO_DIR}" ]; then
    OSXC_REPO_DIR=$(cd "$(dirname "$0")/../../.."; pwd)
fi

CM_REMOTE=github.com/osxc/xc-common
CM_REPO=$OSXC_REPO_DIR/$CM_REMOTE

CS_REMOTE=${1:-github.com/osxc/xc-custom}
CS_REPO=$OSXC_REPO_DIR/$CS_REMOTE

echo "osxc bootstrap script"
echo "====================="
echo ""
echo "You are going to install osxc with:"
echo ""
echo " * Common Remote: $CM_REMOTE"
echo " * Common Path: $CM_REPO"
echo " * Custom Installation Remote: $CS_REMOTE"
echo " * Custom Installation Path: $CS_REPO"
echo ""
echo ""

if [ ! -f "/Library/Developer/CommandLineTools/usr/bin/clang" ]; then
  echo "XCode Tools Installation"
  echo "------------------------"
  echo ""
  echo "This will open up a modal window ... Get back here when ready !"
  sudo /usr/bin/xcode-select --install
  read -p "Continue ? [Enter]"
  echo ""
  echo ""
fi

if [ ! -f "/usr/local/bin/ansible" ]; then
  echo "Ansible installation"
  echo "--------------------"
  export CFLAGS=-Qunused-arguments
  export CPPFLAGS=-Qunused-arguments
  sudo -E easy_install pip
  sudo -E pip install git+https://github.com/ansible/ansible.git # We need at least ansible 1.6
  echo ""
  echo ""
fi

echo "Common tools clone"
echo "------------------"
mkdir -p $CM_REPO
rm -rf $CM_REPO
git clone https://$CM_REMOTE.git $CM_REPO
echo ""
echo ""

echo "Custom tools clone"
echo "------------------"
mkdir -p $CS_REPO
rm -rf $CS_REPO
git clone https://$CS_REMOTE.git $CS_REPO
echo ""
echo ""

echo "Congratulations ! "
echo "----------------- "
echo "You bootstrapped osxc ! "
echo "Now it's time to launch some osxc configuration with: "
echo ""
echo "    cd $CS_REPO"
echo "    ansible-playbook all.yml"
echo ""
echo ""
