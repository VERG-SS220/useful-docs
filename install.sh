#!/bin/bash

spin() {
	local msg=$1; shift
	local log; log=$(mktemp)
	"$@" > "$log" 2>&1 &
	local pid=$! frames='/|\-' i=0

	tput civis 2>/dev/null
	trap 'tput cnorm; kill $pid 2>/dev/null' INT TERM

	while kill -0 "$pid" 2>/dev/null; do
		printf '\r%s %s' "${frames:i++%${#frames}:1}" "$msg"
		sleep 0.1
	done
	wait "$pid"; local rc=$?
	tput cnorm 2>/dev/null
	trap - INT TERM

	if (( rc == 0 )); then
		printf '\r\033[K[OK] %s\n' "$msg"
		rm -f "$log"
	else
		printf '\r\033[K[FAIL] %s (exit %d), last lines of %s:\n' "$msg" "$rc" "$log"
		tail -n 20 "$log"
	fi
	return $rc
}

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
	case "$ID" in
		"ubuntu")
			echo "Current OS is identified as Ubuntu. Proceeding..."
			sleep 5
			;;
		"arch")
			printf 'Ha. I see you use Arch... BTW.\nAlso sorry, but this OS is unsupported... YET\n'
			exit 3
			;;
		*)
			echo "Uh-oh! Current OS is $ID and it is NOT supported."
			exit 3
	esac
	OS=$ID
fi
if [[ $EUID -ne 0 ]] ; then
	echo "Currently detecting that the script is not being ran with SUDO. Relaunching with SUDO..."
	exec sudo -p "$CUSTOM_PROMPT" -- "$SELF" "$@"
fi

case "$OS" in
	"ubuntu")
		export DEBIAN_FRONTEND="noninteractive"
		echo "Installing dependencies for Ubuntu"
		spin "Updating package lists" apt-get update || exit 3
		spin "Installing build tools, headers, firmware, NVIDIA 610 driver and git" \
			apt-get install -y build-essential "linux-headers-$(uname -r)" linux-firmware nvidia-driver-610-open git || exit 3
		spin "Locking Linux Kernel and Linux Headers to avoid driver crash on subsequent reboots" \
			apt-mark hold linux-generic linux-image-generic "linux-headers-$(uname -r)" || exit 3
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
VIRT=$(systemd-detect-virt 2>/dev/null)
VIRT=${VIRT:-none}
echo "Detected virtualization: $VIRT"

if [[ "$VIRT" == "vmware" ]] ; then
	while true ; do
	read -r -t 30 -p "VMware detected. Are you running this script on an ESXi VM? (y/n): " VM
	VM=${VM:-y}
	VM=$(echo "$VM" | tr '[:upper:]' '[:lower:]' )
	[[ "$VM" == "y" || "$VM" == "n" ]] && break
	echo "INPUT INVALID. Answer either y or n."
done

else
	VM="n"
fi
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
		if [[ $VIRT == "none" ]] ; then
			echo "The script is ran in the native environment. Script will remain unchanged."
		else
			echo "The option NO was selected. The script will remain unchanged."
		fi
	
		;;
	*)
		echo "Unknown error. Please try again later. If you've encountered this issue during prod usage, file an issue."
		exit 7
esac

spin "Installing CMPUnlocker..." ./install.sh "$@"
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
