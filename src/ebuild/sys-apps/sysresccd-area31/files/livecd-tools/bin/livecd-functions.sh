#!/bin/bash

# Global Variables:
#    CDBOOT                  -- is booting off CD
#    LIVECD_CONSOLE          -- console that is specified on commandline 
#                            -- (ttyS0, etc) Only defined if passed to kernel
#    LIVECD_CONSOLE_BAUD     -- console baudrate specified
#    LIVECD_CONSOLE_PARITY   -- console parity specified
#    LIVECD_CONSOLE_DATABITS -- console databits specified

[[ ${RC_GOT_FUNCTIONS} != "yes" ]] && [[ -e /etc/init.d/functions.sh ]] && source /etc/init.d/functions.sh

livecd_parse_opt() {
	case "$1" in
		*\=*)
			echo "$1" | cut -f2 -d=
		;;
	esac
}

livecd_check_root() {
	if [ "$(whoami)" != "root" ]
	then
		echo "ERROR: must be root to continue"
		return 1
	fi
}

livecd_get_cmdline() {
	echo "0" > /proc/sys/kernel/printk
	CMDLINE=$(cat /proc/cmdline)
	export CMDLINE
}

no_gl() {
#	einfo "If you have a card that you know is supported by either the ATI or"
#	einfo "NVIDIA binary drivers, please file a bug with the output of lspci"
#	einfo "on http://bugs.gentoo.org so we can resolve this."
	GLTYPE=xorg-x11
}

ati_gl() {
	einfo "ATI card detected."
	if [ -e /usr/lib/xorg/modules/drivers/fglrx_drv.so ] \
	|| [ -e /usr/lib/modules/drivers/fglrx_drv.so ]
	then
#		sed -i \
#			-e 's/ati/fglrx/' \
#			-e 's/radeon/fglrx/' \
#			-e 's/r300/fglrx/' \
#			/etc/X11/xorg.conf
		GLTYPE=ati
	else
		GLTYPE=xorg-x11
	fi
}

nv_gl() {
	einfo "NVIDIA card detected."
	if [ -e /usr/lib/xorg/modules/drivers/nvidia_drv.so ] \
	|| [ -e /usr/lib/modules/drivers/nvidia_drv.so ]
	then
		GLTYPE=nvidia
	else
		GLTYPE=xorg-x11
	fi
}

nv_no_gl() {
	einfo "NVIDIA card detected."
	echo
	if [ -e /usr/lib/xorg/modules/drivers/nvidia_drv.so ] \
	|| [ -e /usr/lib/modules/drivers/nvidia_drv.so ]
	then
		einfo "This card is not supported by the latest version of the NVIDIA"
		einfo "binary drivers.  Switching to the X server's driver instead."
	fi
	GLTYPE=xorg-x11
	sed -i 's/nvidia/nv/' /etc/X11/xorg.conf
}

get_video_cards() {
	VIDEO_CARDS=$(lspci | grep ' VGA ')
	NUM_CARDS=$(echo ${VIDEO_CARDS} | wc -l)
	if [ ${NUM_CARDS} -eq 1 ]
	then
		NVIDIA=$(echo ${VIDEO_CARDS} | grep "nVidia Corporation")
		ATI=$(echo ${VIDEO_CARDS} | grep "ATI Technologies")
		if [ -n "${NVIDIA}" ]
		then
			NVIDIA_CARD=$(echo ${NVIDIA} | awk 'BEGIN {RS=" "} /(NV|nv|G|C)[0-9]+/ {print $1}' | cut -d. -f1 | sed 's/ //' | sed 's:[^0-9]::g')
			# NVIDIA Model reference:
			# http://en.wikipedia.org/wiki/Comparison_of_NVIDIA_Graphics_Processing_Units
			if [ -n "${NVIDIA_CARD}" ]
			then
				if [ $(echo ${NVIDIA_CARD} | cut -dV -f2) -ge 17 ]
				then
					nv_gl
				elif [ $(echo ${NVIDIA_CARD} | cut -dG -f2) -ge 70 ]
				then
					nv_gl
				elif [ $(echo ${NVIDIA_CARD} | cut -dV -f2) -eq 11 ]
				then
					nv_gl
				elif [ $(echo ${NVIDIA_CARD} | cut -dC -f2) -ge 50 ]
				then
					nv_gl
				else
					nv_no_gl
				fi
			else
				no_gl
			fi
		elif [ -n "${ATI}" ]
		then
			ATI_CARD=$(echo ${ATI} | awk 'BEGIN {RS=" "} /(R|RV|RS)[0-9]+/ {print $1}' | sed -e 's/[^0-9]//g')
			if [ $(echo ${ATI_CARD} | grep S) ]
			then
				ATI_CARD_S=$(echo ${ATI_CARD} | cut -dS -f2)
			elif [ $(echo ${ATI_CARD} | grep V) ]
			then
				ATI_CARD_V=$(echo ${ATI_CARD} | cut -dV -f2)
			else
				ATI_CARD=$(echo ${ATI_CARD} | cut -dR -f2)
			fi
			if [ -n "${ATI_CARD_S}" ] && [ ${ATI_CARD_S} -ge 350 ]
			then
				ati_gl
			elif [ -n "${ATI_CARD_V}" ] && [ ${ATI_CARD_V} -ge 250 ]
			then
				ati_gl
			elif [ -n "${ATI_CARD}" ] && [ ${ATI_CARD} -ge 200 ]
			then
				ati_gl
			else
				no_gl
			fi
		else
			no_gl
		fi
	fi
}

get_ifmac() {
	local iface=$1

	# Example: 00:01:6f:e1:7a:06
	cat /sys/class/net/${iface}/address
}


get_ifdriver() {
	local iface=$1

	# Example: ../../../bus/pci/drivers/forcedeth (wanted: forcedeth)
	local if_driver=$(readlink /sys/class/net/${iface}/device/driver)
	basename ${if_driver}
}

get_ifbus() {
	local iface=$1

	# Example: ../../../bus/pci (wanted: pci)
	# Example: ../../../../bus/pci (wanted: pci)
	# Example: ../../../../../../bus/usb (wanted: usb)
	local if_bus=$(readlink /sys/class/net/${iface}/device/bus)
	basename ${if_bus}
}

get_ifproduct() {
	local iface=$1
	local bus=$(get_ifbus ${iface})
	local if_pciaddr
	local if_devname
	local if_usbpath
	local if_usbmanufacturer
	local if_usbproduct

	if [[ ${bus} == "pci" ]]
	then
		# Example: ../../../devices/pci0000:00/0000:00:0a.0 (wanted: 0000:00:0a.0)
		# Example: ../../../devices/pci0000:00/0000:00:09.0/0000:01:07.0 (wanted: 0000:01:07.0)
		if_pciaddr=$(readlink /sys/class/net/${iface}/device)
		if_pciaddr=$(basename ${if_pciaddr})

		# Example: 00:0a.0 Bridge: nVidia Corporation CK804 Ethernet Controller (rev a3)
		#  (wanted: nVidia Corporation CK804 Ethernet Controller)
		if_devname=$(lspci -s ${if_pciaddr})
		if_devname=${if_devname#*: }
		if_devname=${if_devname%(rev *)}
	fi

	if [[ ${bus} == "usb" ]]
	then
		if_usbpath=$(readlink /sys/class/net/${iface}/device)
		if_usbpath=/sys/class/net/${iface}/$(dirname ${if_usbpath})
		if_usbmanufacturer=$(< ${if_usbpath}/manufacturer)
		if_usbproduct=$(< ${if_usbpath}/product)

		[[ -n ${if_usbmanufacturer} ]] && if_devname="${if_usbmanufacturer} "
		[[ -n ${if_usbproduct} ]] && if_devname="${if_devname}${if_usbproduct}"
	fi

	if [[ ${bus} == "ieee1394" ]]
	then
		if_devname="IEEE1394 (FireWire) Network Adapter";
	fi

	echo ${if_devname}
}

get_ifdesc() {
	local iface=$1
	desc=$(get_ifproduct ${iface})
	if [[ -n ${desc} ]]
	then
		echo $desc
		return;
	fi

	desc=$(get_ifdriver ${iface})
	if [[ -n ${desc} ]]
	then
		echo $desc
		return;
	fi

	desc=$(get_ifmac ${iface})
	if [[ -n ${desc} ]]
	then
		echo $desc
		return;
	fi

	echo "Unknown"
}

livecd_console_settings() {
	# scan for a valid baud rate
	case "$1" in
		300*)
			LIVECD_CONSOLE_BAUD=300
		;;
		600*)
			LIVECD_CONSOLE_BAUD=600
		;;
		1200*)
			LIVECD_CONSOLE_BAUD=1200
		;;
		2400*)
			LIVECD_CONSOLE_BAUD=2400
		;;
		4800*)
			LIVECD_CONSOLE_BAUD=4800
		;;
		9600*)
			LIVECD_CONSOLE_BAUD=9600
		;;
		14400*)
			LIVECD_CONSOLE_BAUD=14400
		;;
		19200*)
			LIVECD_CONSOLE_BAUD=19200
		;;
		28800*)
			LIVECD_CONSOLE_BAUD=28800
		;;
		38400*)
			LIVECD_CONSOLE_BAUD=38400
		;;
		57600*)
			LIVECD_CONSOLE_BAUD=57600
		;;
		115200*)
			LIVECD_CONSOLE_BAUD=115200
		;;
	esac
	if [ "${LIVECD_CONSOLE_BAUD}" = "" ]
	then
		# If it's a virtual console, set baud to 38400, if it's a serial
		# console, set it to 9600 (by default anyhow)
		case ${LIVECD_CONSOLE} in 
			tty[0-9])
				LIVECD_CONSOLE_BAUD=38400
			;;
			*)
				LIVECD_CONSOLE_BAUD=9600
			;;
		esac
	fi
	export LIVECD_CONSOLE_BAUD

	# scan for a valid parity
	# If the second to last byte is a [n,e,o] set parity
	local parity
	parity=$(echo $1 | rev | cut -b 2-2)
	case "$parity" in
		[neo])
			LIVECD_CONSOLE_PARITY=$parity
		;;
	esac
	export LIVECD_CONSOLE_PARITY	

	# scan for databits
	# Only set databits if second to last character is parity
	if [ "${LIVECD_CONSOLE_PARITY}" != "" ]
	then
		LIVECD_CONSOLE_DATABITS=$(echo $1 | rev | cut -b 1)
	fi
	export LIVECD_CONSOLE_DATABITS
	return 0
}

livecd_read_commandline() {
	livecd_get_cmdline || return 1

	for x in ${CMDLINE}
	do
		case "${x}" in
			cdroot)
				CDBOOT="yes"
				RC_NO_UMOUNTS="^(/|/dev|/dev/pts|/lib/rcscripts/init.d|/proc|/proc/.*|/sys|/mnt/livecd|/newroot)$"
				export CDBOOT RC_NO_UMOUNTS
			;;
			cdroot\=*)
				CDBOOT="yes"
				RC_NO_UMOUNTS="^(/|/dev|/dev/pts|/lib/rcscripts/init.d|/proc|/proc/.*|/sys|/mnt/livecd|/newroot)$"
				export CDBOOT RC_NO_UMOUNTS
			;;
			console\=*)
				local live_console
				live_console=$(livecd_parse_opt "${x}")

				# Parse the console line. No options specified if
				# no comma
				LIVECD_CONSOLE=$(echo ${live_console} | cut -f1 -d,)
				if [ "${LIVECD_CONSOLE}" = "" ]
				then
					# no options specified
					LIVECD_CONSOLE=${live_console}
				else
					# there are options, we need to parse them
					local livecd_console_opts
					livecd_console_opts=$(echo ${live_console} | cut -f2 -d,)
					livecd_console_settings  ${livecd_console_opts}
				fi
				export LIVECD_CONSOLE
			;;
		esac
	done
	return 0
}
