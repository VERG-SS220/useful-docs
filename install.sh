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
		sudo apt-get update && sudo apt-get install -y build-essential linux-headers-$(uname -r) linux-firmware nvidia-driver-610-open git
		;;
	*)
		echo "Current system is unsupported."
		exit 3;
esac

echo "Cloning amoghmunikote/cmpunlocker for the CMP170HX drive..."
sudo rm -rf  cmpunlocker
git clone $GIT_REPO
cd cmpunlocker
read -r -t 30 -p "Are you running this script on ESXi VM? (y/n): " VM

VM=${VM:-y}

VM=$(echo "$VM" | tr '[:upper:]' '[:lower:]' )
case "$VM" in
	y)
		echo "Okay. Deleting the BAR1 resize file to avoid deadlocking the GPU.\n The backup of a build.sh script is stored as a safety measure."
		rm -f $INSTALL_DIR/cmpunlocker/driver/patches/bar1-resize-unlock.patch
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

if [[ $EUID -eq 0 ]] ; then
./install.sh
else
	echo "Currently detecting that this script isn't launched with SUDO..."
	if sudo -p "$CUSTOM_PROMPT" "$0" "$@" ; then
		echo "Identification successful!"
	else
		echo "CRITICAL ERROR! PASSWORD IS INVALID OR ACCESS DENIED."
		exit 5
	fi
fi
if [[ $? -eq 0 ]]; then
	echo "There seems to have been some sort of a problem encountered while installing the cmpunlocker. Exit code is: $?"
else
	echo "Congratulations! CMPUnlocker has been successfully installed."
fi
if [[ $VM -eq "Y" ]] ; then
	echo "Proceed by powering off your VM and then powering it on. The unlocker should take effect."
else
	echo "Proceed with doing a cold reboot. The unlocker should take effect."
fi
exit 0
