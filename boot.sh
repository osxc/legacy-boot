REPO_DIR="${HOME}/src"

CM_REMOTE="github.com/osxc/xc-common"
CM_REPO=$REPO_DIR/$CM_REMOTE

CS_REMOTE=${1:-github.com/osxc/xc-custom}
CS_REPO=$REPO_DIR/$CS_REMOTE

ANSIBLE_BINARY="/usr/local/bin/ansible"
ANSIBLE_MINIMUM_VERSION="1.6"

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
read -p "Continue ? [Enter]"
echo ""
echo ""

# Check OS to provide correct method/URL for CLI Tools installation
declare -x OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')

installDevTools(){
    # Wholeheartedly lifted from
    #  https://github.com/timsutton/osx-vm-templates/blob/master/scripts/xcode-cli-tools.sh
    if [ "$OSX_VERS" -ge 9 ]; then
        # create the placeholder file that's checked by the CLI updates .dist in Apple's SUS catalog
        /usr/bin/touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        # find the product id with "Developer" in the name
        PRODID=$(/usr/sbin/softwareupdate -l | awk '/Developer/{print x};{x=$0}' | awk '{print $2}')
        # install it (amazingly, it won't find the update if we put the update ID in double-quotes)
        /usr/sbin/softwareupdate -i $PRODID -v
    # on 10.7/10.8, we instead download from public download URLs, which can be found in
    # the dvtdownloadableindex:
    # https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex
    else
        [ "$OSX_VERS" -eq 7 ] && DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg
        [ "$OSX_VERS" -eq 8 ] && DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_osx_mountain_lion_april_2014.dmg
        TOOLSPATH="/tmp/clitools.dmg"
        /usr/bin/curl "$DMGURL" -o "$TOOLSPATH"
        TMPMOUNT=`/usr/bin/mktemp -d /tmp/clitools.XXXX`
        /usr/bin/hdiutil attach "$TOOLSPATH" -mountpoint "$TMPMOUNT"
        /usr/sbin/installer -pkg "$(find $TMPMOUNT -name '*.mpkg')" -target /
        /usr/bin/hdiutil detach "$TMPMOUNT"
        /bin/rm -rf "$TMPMOUNT"
        /bin/rm "$TOOLSPATH"
        exit
    fi
}
# Build array of most probable receipts from CLI tools for current & past OS versions, partially from
# https://github.com/Homebrew/homebrew/blob/208f963cf2/Library/Homebrew/os/mac/xcode.rb#L147-L150
declare -xa BUNDLE_IDS=('com.apple.pkg.DeveloperToolsCLI' \
    'com.apple.pkg.DeveloperToolsCLILeo' 'com.apple.pkg.CLTools_Executables' \
    'com.apple.pkg.XcodeMAS_iOSSDK_7_0')
# Set flag for the presence of a CLI tools receipt
declare -xi XCODE_CLI=0
# Iterate over array, break out and skip install if we get a zero return code
for id in ${BUNDLE_IDS[@]}; do
    /usr/sbin/pkgutil --pkg-info=$id > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        echo "Found " $id ", Xcode Developer CLI Tools install not needed"
        echo ""
        echo ""
        ((XCODE_CLI++))
        break
    fi
done

if [[ $XCODE_CLI -ne 1 ]]; then
    echo "XCode Tools Installation"
    echo "------------------------"
    echo ""
    echo "Please wait while Xcode is silently installed"
    installDevTools
    echo ""
    echo ""
fi

if [ ! -f "${ANSIBLE_BINARY}" ]; then
  should_install_ansible=true
else
  ansible_correct_version_installed=`${ANSIBLE_BINARY} --version 2>&1 | cut -c 9- | grep "${ANSIBLE_MINIMUM_VERSION}"`

  if [ "${ansible_correct_version_installed}" ]; then
    should_install_ansible=false
  else
    should_install_ansible=true
  fi
fi

if [ "${should_install_ansible}" == true ]; then
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
