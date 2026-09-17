#!/bin/bash

INSTALL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
GIT_REPO="https://github.com/amoghmunikote/cmpunlocker"
CUSTOM_PROMPT="Please enter your password to identify yourself."
SELF=$(readlink -f "$0")
CONSTANTS="$INSTALL_DIR/cmpunlocker/common/constants.yaml"

if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
	echo "Internet is established successfully. Proceeding..."
else
	echo "Please verify that the internet is connected successfully and retry"
	exit 1;
fi


if [[ "$OSTYPE" == "darwin"* ]] ; then
	echo "This program is only intended for Linux OSes"
elif [ -f /etc/os-release ] ; then
	# shellcheck source=/dev/null
	. /etc/os-release
	OS=$ID
	echo "Successfully identified OS as $OS"
else
	OS="Unknown"
	echo "This operating system is currently unsupported."
	exit 2;
fi
if [[ $EUID -ne 0 ]] ; then
	echo "Currently detecting that the script is not being ran with SUDO. Relaunching with SUDO..."
	exec sudo -p "$CUSTOM_PROMPT" -- "$SELF" "$@"
fi

case "$OS" in
	"ubuntu" | "debian")
		export DEBIAN_FRONTEND="noninteractive"
		echo "Installing dependencies for Ubuntu/Debian..."
		sudo apt-get update && sudo apt-get install -y build-essential "linux-headers-$(uname -r)" linux-firmware nvidia-driver-610-open git || exit 3
		;;
	*)
		echo "Current system is unsupported."
		exit 3;
esac

echo "Cloning amoghmunikote/cmpunlocker for the CMP170HX drive..."
cd "$INSTALL_DIR" || exit 4
sudo rm -rf cmpunlocker
git clone "$GIT_REPO" || exit 4
cd cmpunlocker || exit 4
read -r -t 30 -p "Are you running this script on ESXi VM? (y/n): " VM

VM=${VM:-y}

VM=$(echo "$VM" | tr '[:upper:]' '[:lower:]' )
case "$VM" in
	y)
		echo "Okay. Deleting the BAR1 resize file to avoid deadlocking the GPU."
		echo "Backups of build.sh and constants.yaml are kept as .bak files until the next run."
		rm -f "$INSTALL_DIR/cmpunlocker/driver/patches/bar1-resize-unlock.patch"
		BUILD_SCRIPT='driver/build.sh'
		if [ -f "$BUILD_SCRIPT" ] ; then
		sed -i.bak '/bar1_resize/,+2d' "$CONSTANTS"
		sed -i.bak '/bar1-resize/d' "$BUILD_SCRIPT"
		echo "Script successfully modified."
		fi
		;;
	n)
		echo "The option NO was selected. The script will remain unchanged."
		;;
	*)
		echo "Unknown error. Please try again later. If you've encountered this issue during prod usage, file an issue."
		exit 7
esac

./install.sh "$@"
rc=$?
if [[ $rc -ne 0 ]]; then
	echo "There seems to have been some sort of a problem encountered while installing the cmpunlocker. Exit code is: $rc"
	exit $rc
fi
echo "Congratulations! CMPUnlocker has been successfully installed."
if [[ $VM == "y" ]] ; then
	echo "Proceed by powering off your VM and then powering it on. The unlocker should take effect."
else
	echo "Proceed with doing a cold reboot. The unlocker should take effect."
fi
exit 0
