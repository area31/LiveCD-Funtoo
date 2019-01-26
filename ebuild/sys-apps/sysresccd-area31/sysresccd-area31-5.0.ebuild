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
	insinto /etc/init.d
	newinitd "${S}"/autorun autorun
	newinitd "${S}"/dostartx dostartx
	newinitd "${S}"/load-fonts-keymaps load-fonts-keymaps
	newinitd "${S}"/sysresccd sysresccd
	newinitd "${S}"/netconfig2 netconfig2
	dosbin "${S}"/sysresccd-scripts/autorun
	dosbin "${S}"/sysresccd-scripts/knx-hdinstall
	dosbin "${S}"/sysresccd-scripts/mountsys
	dosbin "${S}"/sysresccd-scripts/sysreport
	dosbin "${S}"/sysresccd-scripts/sysresccd-backstore
	dosbin "${S}"/sysresccd-scripts/sysresccd-cleansys
	dosbin "${S}"/sysresccd-scripts/sysresccd-custom
	dosbin "${S}"/sysresccd-scripts/sysresccd-pkgstats
	dosbin "${S}"/sysresccd-scripts/sysresccd-usbstick
	dosbin "${S}"/sysresccd-area31 || die
}
