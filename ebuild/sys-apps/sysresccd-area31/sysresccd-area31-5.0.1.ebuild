EAPI="5"

inherit eutils

DESCRIPTION="Admin scripts provided with RescueCD Area31 Hackerspace"
HOMEPAGE="https://www.area31.net.br/wiki/RescueCD_oficial"
SRC_URI="https://area31.net.br/downloads/ebuilds/releases/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 hppa mips ppc ppc64 sparc x86"
IUSE=""

# Please remove these ebuilds first:
#sys-apps/sysresccd-scripts
#sys-apps/sysresccd-custom

DEPEND=">=dev-lang/python-2.4.0
		dev-util/dialog
		dev-libs/libisoburn
		sys-fs/squashfs-tools
		sys-apps/hwsetup
		app-backup/fsarchiver
		sys-apps/util-linux
		app-admin/pwgen
		!sys-apps/sysresccd-custom
		!sys-apps/sysresccd-scripts
		!app-misc/livecd-tools
		>=app-shells/bash-3.1"
RDEPEND="${DEPEND}"

src_compile() {
	einfo "Nothing to compile, install scripts only"
}

S="${WORKDIR}/files"

src_install()
{
	insinto /etc/area31
	doins "${S}"/area31-logo-menu-lxqt.png
	doins "${S}"/Bg-blur-area31_1920_x_1200.png
	doins "${S}"/Bg-blur-area31-2017_1920_x_1200.png
	doins "${S}"/logo_linux_clut224.ppm
	doins "${S}"/xinitrc
	fperms +x /etc/area31/xinitrc
	dosym /etc/area31/xinitrc /root/.xinitrc
	insinto /usr/share/"${PN}"
	doins "${S}"/sysresccd-area31-umount
	doins "${S}"/sysresccd-area31-mount
	doins "${S}"/sysresccd-area31-swap
	doins "${S}"/sysresccd-area31-partition
	doins "${S}"/sysresccd-area31-targets
	doins "${S}"/sysresccd-area31-help
	doins "${S}"/sysresccd-area31-help.txt
	doins "${S}"/sysresccd-area31-keymap
	doins "${S}"/sysresccd-area31-showmount
	doins "${S}"/sysresccd-area31-format
	insinto /root/.config/openbox
	doins "${S}"/rootdir/.config/openbox/autostart
	doins "${S}"/rootdir/.config/openbox/rc.xml
	fperms +x /root/.config/openbox/autostart
	insinto /root/.config/termite
	doins "${S}"/rootdir/.config/termite/config
	insinto /etc/conf.d
	doins "${S}"/livecd-tools/confd/autoconfig
	insinto /etc/init.d
	newinitd "${S}"/autorun autorun
	newinitd "${S}"/dostartx dostartx
	newinitd "${S}"/load-fonts-keymaps load-fonts-keymaps
	newinitd "${S}"/sysresccd sysresccd
	newinitd "${S}"/netconfig2 netconfig2
	newinitd "${S}"/livecd-tools/initd/autoconfig autoconfig
	newinitd "${S}"/livecd-tools/initd/gpm-pre gpm-pre
	newinitd "${S}"/livecd-tools/initd/fixinittab fixinittab
	newinitd "${S}"/livecd-tools/initd/unmute unmute
	newinitd "${S}"/livecd-tools/initd/hwsetup hwsetup
	dosbin "${S}"/livecd-tools/bin/net-setup
	dosbin "${S}"/livecd-tools/bin/livecd-functions.sh
	dosbin "${S}"/sysresccd-scripts/autorun
	dosbin "${S}"/sysresccd-scripts/knx-hdinstall
	dosbin "${S}"/sysresccd-scripts/mountsys
	dosbin "${S}"/sysresccd-scripts/sysreport
	dosbin "${S}"/sysresccd-scripts/sysresccd-backstore
	dosbin "${S}"/sysresccd-scripts/sysresccd-cleansys
	dosbin "${S}"/sysresccd-scripts/sysresccd-custom
	dosbin "${S}"/sysresccd-scripts/sysresccd-pkgstats
	dosbin "${S}"/sysresccd-scripts/sysresccd-usbstick
	dosbin "${S}"/sysresccd-area31-setservices
	dosbin "${S}"/sysresccd-area31 || die
}

pkg_postinst() {
	einfo ""
	einfo "This is Area31 Hackerspace LiveCD Tools."
	einfo "Release ${P}"
	einfo "More infos: https://area31.net.br/wiki/RescueCD_oficial"
	einfo ""
	elog "${P} is now installed. Please run this /usr/sbin/sysresccd-area31-setservices to adjust various services on boot."
	elog "Now, build your own LiveCD: https://www.funtoo.org/Make_your_own_LiveCD_using_Funtoo_Linux"
	einfo ""
}
