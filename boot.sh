REPO_DIR=~/src

CM_REMOTE=github.com/osxc/xc-common
CM_REPO=$REPO_DIR/$RL_REMOTE

CS_REMOTE=$1
CS_REPO=$REPO_DIR/$CS_REMOTE

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

echo "Ansible installation"
echo "--------------------"
sudo easy_install pip
sudo pip install ansible
echo ""
echo ""

echo "Clone with tarball"
echo "------------------"
mkdir -p $CM_REPO
mkdir -p $CS_REPO

curl -L "https://$CM_REMOTE/tarball/master" | tar --strip-components=1 -zx -C $CM_REPO
curl -L "https://$CS_REMOTE/tarball/master" | tar --strip-components=1 -zx -C $CS_REPO
echo ""
echo ""

echo "First Ansible Run"
echo "-----------------"
ln -s $CM_REPO/roles/common $CS_REPO/roles/common
ansible-playbook -i $CM_REPO/hosts $CS_REPO/all.yml
echo ""
echo ""
