# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

DESCRIPTION="A tool used to gather system information and paste it online"
HOMEPAGE="https://github.com/smartass101/genalyze"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86"
IUSE=""

RDEPEND="app-text/wgetpaste
    sys-apps/pciutils"
    
DEPEND="${RDEPEND}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	install -D ./* 
}


src_install() {
	mv genalyze.sh genalyze
	dobin genalyze || die
}