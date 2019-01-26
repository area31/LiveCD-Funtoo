#!/bin/bash

get_ifbus() {
	local iface=$1

	# Example: ../../../bus/pci (wanted: pci)
	# Example: ../../../../bus/pci (wanted: pci)
	# Example: ../../../../../../bus/usb (wanted: usb)
	local if_bus=$(readlink /sys/class/net/${iface}/device/subsystem)
	[[ -e "${if_bus}" ]] && basename ${if_bus}
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

get_ifdriver() {
	local iface=$1

	# Example: ../../../bus/pci/drivers/forcedeth (wanted: forcedeth)
	local if_driver=$(readlink /sys/class/net/${iface}/device/driver)
	[[ -e "${if_driver}" ]] && basename ${if_driver}
}

get_ifmac() {
	local iface=$1

	# Example: 00:01:6f:e1:7a:06
	cat /sys/class/net/${iface}/address
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

show_ifmenu() {
	local old_ifs="${IFS}"
	local opts
	IFS="
"
	for ifname in $(ifconfig -a | grep "^[^ ]" | cut -d : -f 1); do
		ifname="${ifname%% *}"
		[[ ${ifname} == "lo" ]] && continue
		[[ ${ifname} == "sit0" ]] && continue
		opts="${opts} ${ifname} '$(get_ifdesc ${ifname})'"
	done
	IFS="${old_ifs}"

	dialog --visit-items --trim \
		--menu "Please select the interface that you wish to configure from the list below:" 0 0 0 $opts 2>iface
	[[ $? -gt 0 ]] && exit
	iface=$(< iface)
}

show_ifconfirm() {
	local iface=$1
	local if_mac=$(get_ifmac ${iface})
	local if_driver=$(get_ifdriver ${iface})
	local if_bus=$(get_ifbus ${iface})
	local if_product=$(get_ifproduct ${iface})

	local text="Details for network interface ${iface} are shown below.\n\nInterface name: ${iface}\n"
	[[ -n ${if_product} ]] && text="${text}Device: ${if_product}\n"
	[[ -n ${if_mac} ]] && text="${text}MAC address: ${if_mac}\n"
	[[ -n ${if_driver} ]] && text="${text}Driver: ${if_driver}\n"
	[[ -n ${if_bus} ]] && text="${text}Bus type: ${if_bus}\n"
	text="${text}\nIs this the interface that you wish to configure?"

	if ! dialog --visit-items --title "Interface details" --yesno \
		"${text}" 15 70
	then
		result="no"
	else
		result="yes"
	fi
}

config_wireless() {
	cd /tmp/setup.opts
	dialog --visit-items --title "SSID" \
		--inputbox "Please enter your SSID, or leave blank for selecting the nearest open network" \
		20 50 2> ${iface}.SSID
	SSID=$(tail -n 1 ${iface}.SSID)
	if [ -n "${SSID}" ]
	then
		dialog --visit-items --title "WEP (Part 1)" \
			--menu "Does your network use encryption?" \
			20 60 7 1 "Yes" 2 "No" 2> ${iface}.WEP
		WEP=$(tail -n 1 ${iface}.WEP)
		case ${WEP} in
			1)
				dialog --visit-items --title "WEP (Part 2)" \
					--menu "Are you entering your WEP key in HEX or ASCII?" \
					20 60 7 1 "HEX" 2 "ASCII" 2> ${iface}.WEPTYPE
				WEP_TYPE=$(tail -n 1 ${iface}.WEPTYPE)
				case ${WEP_TYPE} in
					1)
						dialog --visit-items --title "WEP (Part 3)" \
							--inputbox "Please enter your WEP key in the form of XXXX-XXXX-XX for 64-bit or XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XX for 128-bit" \
							20 50 2> ${iface}.WEPKEY
						WEP_KEY=$(tail -n 1 ${iface}.WEPKEY)
						if [ -n "${WEP_KEY}" ]
						then
							iwconfig ${iface} essid "${SSID}"
							iwconfig ${iface} key "${WEP_KEY}"
						fi
					;;
					2)
						dialog --visit-items --title "WEP (Part 3)" \
							--inputbox "Please enter your WEP key in ASCII form.  This should be 5 or 13 characters for either 64-bit or 128-bit encryption, respectively" \
							20 50 2> ${iface}.WEPKEY
						WEP_KEY=$(tail -n 1 ${iface}.WEPKEY)
						if [ -n "${WEP_KEY}" ]
						then
							iwconfig ${iface} essid "${SSID}"
							iwconfig ${iface} key "s:${WEP_KEY}"
						fi
					;;
				esac
			;;
			2)
				iwconfig ${iface} essid "${SSID}"
				iwconfig ${iface} key off
			;;
		esac
	fi
}

config_wpa() {
	cd /tmp/setup.opts
	dialog --visit-items --title "SSID" \
		--inputbox "Please enter your SSID" \
		20 50 2> ${iface}.SSID
	SSID=$(tail -n 1 ${iface}.SSID)
	dialog --visit-items --title "WPA(2)-PSK" \
		--inputbox "Please enter your WPA Preshared key in ASCII form.  This should be between 8 and 63 characters" \
		20 50 2> ${iface}.WPAKEY
	WPA_KEY=$(tail -n 1 ${iface}.WPAKEY)
	if [ -n "${WPA_KEY}" ]
	then
		mkdir -p /etc/wpa_supplicant
		wpa_passphrase "${SSID}" "${WPA_KEY}" > /etc/wpa_supplicant/wpa_supplicant.conf
		wpa_supplicant -B -i${iface} -c /etc/wpa_supplicant/wpa_supplicant.conf -Dnl80211,wext
	fi
}

config_ip() {
	cd /tmp/setup.opts
	dialog --visit-items --title "TCP/IP setup" \
		--menu "You can use DHCP to automatically configure a network interface or you can specify an IP and related settings manually.  Choose one option:" \
		20 60 7 1 "Use DHCP to auto-detect my network settings" \
		2 "Specify an IP address manually" 2> ${iface}.DHCP
	DHCP=$(tail -n 1 ${iface}.DHCP)
	case ${DHCP} in
		1)
			/sbin/dhcpcd -n -t 10 -h $(hostname) ${iface} &
		;;
		2)

			dialog --visit-items --title "TCP/IP setup" \
				--menu "Do you want to use ifconfig (192.168.0.1 255.255.255.0) or iproute2 (192.168.0.1/24) syntax?.  Choose one option:" \
				20 60 7 1 "Use ifconfig to configure the network" \
				2 "Use iproute2 to configure the network" 2> ${iface}.SYNTAX
			SYNTAX=$(tail -n 1 ${iface}.SYNTAX)
			case ${SYNTAX} in
				1)

					dialog --visit-items --title "IP address" \
					--inputbox "Please enter an IP address for ${iface}:" \
					20 50 "192.168.1.1" 2> ${iface}.IP
					IP=$(tail -n 1 ${iface}.IP)
					BC_TEMP=$(echo $IP|cut -d . -f 1).$(echo $IP|cut -d . -f 2).$(echo $IP|cut -d . -f 3).255
					dialog --visit-items --title "Broadcast address" \
						--inputbox "Please enter a Broadcast address for ${iface}:" \
						20 50 "${BC_TEMP}" 2> ${iface}.BC
					BROADCAST=$(tail -n 1 ${iface}.BC)
					dialog --visit-items --title "Network mask" \
						--inputbox "Please enter a Network Mask for ${iface}:" \
						20 50 "255.255.255.0" 2> ${iface}.NM
					NETMASK=$(tail -n 1 ${iface}.NM)
					dialog --visit-items --title "Gateway" \
						--inputbox "Please enter a Gateway for ${iface} (hit enter for none:)" \
						20 50 2> ${iface}.GW
					GATEWAY=$(tail -n 1 ${iface}.GW)

					ifconfig ${iface} ${IP} broadcast ${BROADCAST} netmask ${NETMASK}

					if [ -n "${GATEWAY}" ]
					then
						route add default gw ${GATEWAY} dev ${iface} netmask 0.0.0.0 metric 1
					fi
				;;
				2)

					dialog --visit-items --title "IP address" \
					--inputbox "Please enter an IP address for ${iface}:" \
					20 50 "192.168.1.1/24" 2> ${iface}.IP
					IP=$(tail -n 1 ${iface}.IP)
					dialog --visit-items --title "Gateway" \
						--inputbox "Please enter a Gateway for ${iface} (hit enter for none:)" \
						20 50 2> ${iface}.GW
					GATEWAY=$(tail -n 1 ${iface}.GW)

					ip addr add ${IP} dev ${iface}

					if [ -n "${GATEWAY}" ]
					then
						ip route add default via ${GATEWAY}
					fi
			esac

			dialog --visit-items --title "DNS server"\
				--inputbox "Please enter a name server to use (hit enter for none:)" \
				20 50 2> ${iface}.DNS
			DNS=$(tail -n 1 ${iface}.DNS)
			if [ -n "${DNS}" ]
			then
				dialog --visit-items --title "DNS Search Suffix" \
					--inputbox "Please enter any domains which you would like to search on DNS queries (hit enter for none:)" \
					20 50 2> ${iface}.SUFFIX
				SUFFIX=$(tail -n 1 ${iface}.SUFFIX)
				echo "nameserver ${DNS}" > /etc/resolv.conf
				if [ -n "${SUFFIX}" ]
				then
					echo "search ${SUFFIX}" >> /etc/resolv.conf
				fi
			fi
		;;
	esac
}

write_wireless_conf() {
	cd /tmp/setup.opts
	SSID=$(tail -n 1 ${iface}.SSID)
	if [ -n "${SSID}" ]
	then
		echo "" >> /etc/conf.d/net
		echo "# This wireless configuration file was built by net-setup" > /etc/conf.d/net
		WEP=$(tail -n 1 ${iface}.WEPTYPE)
		case ${WEP} in
			1)
				WEP_TYPE=$(tail -n 1 ${iface}.WEPTYPE)
				if [ -n "${WEP_TYPE}" ]
				then
					WEP_KEY=$(tail -n 1 ${iface}.WEPKEY)
					if [ -n "${WEP_KEY}" ]
					then
						SSID_TRANS=$(echo ${SSID//[![:word:]]/_})
						case ${WEP_TYPE} in
							1)
								echo "key_${SSID_TRANS}=\"${WEP_KEY} enc open\"" >> /etc/conf.d/net
							;;
							2)
								echo "key_${SSID_TRANS}=\"s:${WEP_KEY} enc open\"" >> /etc/conf.d/net
							;;
						esac
					fi
				fi
			;;
			2)
				:
			;;
		esac
		echo "preferred_aps=\"${SSID}\"" >> /etc/conf.d/net
		echo "associate_order=\"forcepreferredonly\"" >> /etc/conf.d/net
	fi
}

write_wpa_conf() {
	cd /tmp/setup.opts
	SSID=$(tail -n 1 ${iface}.SSID)
	if [ -n "${SSID}" ]
	then
		echo "" >> /etc/conf.d/net
		echo "# This wireless configuration file was built by net-setup" > /etc/conf.d/net
		echo "modules_${iface}=\"wpa_supplicant\"" >> /etc/conf.d/net
		echo "wpa_supplicant_${iface}=\"-Dnl80211,wext\"" >> /etc/conf.d/net
	fi
}

write_net_conf() {
	cd /tmp/setup.opts
	echo "" >> /etc/conf.d/net
	echo "# This network configuration was written by net-setup" >> /etc/conf.d/net
	DHCP=$(tail -n 1 ${iface}.DHCP)
	case ${DHCP} in
		1)
			echo "config_${iface}=\"dhcp\"" >> /etc/conf.d/net
		;;
		2)
			IP=$(tail -n 1 ${iface}.IP)
			BROADCAST=$(tail -n 1 ${iface}.BC)
			NETMASK=$(tail -n 1 ${iface}.NM)
			GATEWAY=$(tail -n 1 ${iface}.GW)
			if [ -n "${IP}" -a -n "${BROADCAST}" -a -n "${NETMASK}" ]
			then
				echo "config_${iface}=\"${IP} broadcast ${BROADCAST} netmask ${NETMASK}\"" >> /etc/conf.d/net
				if [ -n "${GATEWAY}" ]
				then
					echo "routes_${iface}=\"default via ${GATEWAY}\"" >> /etc/conf.d/net
				fi
			fi
		;;
	esac
}

if [ ! -x $(which dialog) ]
then
	echo "ERROR: The dialog utility is required for net-setup.  Exiting!"
	exit 1
fi

if [ "$(whoami)" != "root" ]
then
	echo "ERROR: must be root to continue"
	exit 1
fi

if [ -z "${1}" ]
then
	show_ifmenu
	echo $iface
else
	iface="${1}"
fi

[ ! -d /tmp/setup.opts ] && mkdir -p /tmp/setup.opts
cd /tmp/setup.opts

while true; do
	show_ifconfirm $iface
	[[ $result == "yes" ]] && break
	show_ifmenu
done

dialog --visit-items --title "Network setup" \
	--menu "This script is designed to setup both wired and wireless network settings.  All questions below apply to the ${iface} interface only.  Choose one option:" \
	20 60 7 1 "My network is wired" 2 "My network is wireless (Open/WEP)" \
	3 "My network is wireless (WPA-PSK/WPA2-PSK)" 2> ${iface}.WIRED_WIRELESS
WIRED_WIRELESS=$(tail -n 1 ${iface}.WIRED_WIRELESS)
case ${WIRED_WIRELESS} in
	1)
		config_ip
		;;
	2)
		config_wireless
		config_ip
		write_wireless_conf
		;;
	3)
		config_wpa
		config_ip
		write_wpa_conf
		;;
esac
write_net_conf

echo "Type \"ifconfig\" to make sure the interface was configured correctly."

# vim: ts=4
