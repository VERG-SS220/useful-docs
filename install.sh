#!/bin/bash

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

case "$OS" in
	"ubuntu" | "debian")
		echo "Installing dependencies for Ubuntu/Debian..."
		sudo apt install -y build-essential linux-headers-$(uname -r) linux-firmware nvidia-driver-610-open git
		;;
	*)
		echo "Current system is unsupported."
		exit 3;
esac

echo "Cloning amoghmunikote/cmpunlocker for the CMP170HX drive..."
git clone https://github.com/amoghmunikote/cmpunlocker
cd cmpunlocker
read -r -p "Are you running this script on ESXi VM? (Y/n): " VM

VM =${VM:-y}

VM=$(echo "$VM" | tr '[:upper:]' '[:lower:]' )

case "$VM" in
	Y)
		echo "Okay. Deleting the BAR1 resize file to avoid deadlocking the GPU.\n The backup of a build.sh script is stored as a safety measure."
		rm patches/bar1-resize-unlock.patch
		BUILD_SCRIPT='driver/build.sh'
		if [ -f "$BUILD_SCRIPT" ] ; then
		sed -i.bak '/bar1-resize-unlock.patch/d' "$BUILD_SCRIPT"
		echo "Script successfully modified."
		fi
		;;
	N)
		echo "The option NO was selected. The script will remain unchanged."
		;;
esac

if [[ $EUID -eq 0 ]] ; then
./install.sh
else
	echo "Currently detecting that this script isn't launched with SUDO..."
	SUDO_PROMPT="To proceed, enter your password and press ENTER..."
	if sudo -p "$SUDO_PROMPT" "$0" "$@" ; then
		exit 0
	else
		echo "CRITICAL ERROR! PASSWORD IS INVALID OR ACCESS DENIED."
		exit 5
	fi
fi
echo "Congratulations! CMPUnlocker has been successfully installed."
if [[ $VM -eq "Y" ]] ; then
	echo "Proceed by powering off your VM and then powering it on. The unlocker should take effect."
else
	echo "Proceed with doing a cold reboot. The unlocker should take effect."
fi
exit 0

