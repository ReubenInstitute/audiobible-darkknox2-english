#!/bin/sh
# Build one small audiobible-darkknox2-english-<book>-<chapter> deb per
# chapter present, plus the audiobible-darkknox2-english meta package that
# Depends on all of them pinned to their exact built versions. Editing one
# chapter's audio only touches that chapter's deb + regenerates the meta
# package's Depends line -- never the whole corpus.
# Usage: packaging/deb/build.sh
set -eu

cd "$(dirname "$0")/../.."
REPO_ROOT="$(pwd)"
PKG_DIR="$REPO_ROOT/debian-pkg"
rm -rf "$PKG_DIR"

DEPENDS=""
for group in $(ls *.mp3 | cut -d. -f1,2 | sort -u); do
	book=${group%.*}
	chapter=${group#*.}
	pkg="audiobible-darkknox2-english-${book}-${chapter}"
	ver="0.$(git rev-list --count HEAD -- "${group}".*.mp3)"

	CH_DIR="$PKG_DIR/${pkg}"
	mkdir -p "$CH_DIR/DEBIAN" "$CH_DIR/var/lib/audiobible/english"
	cp "${group}".*.mp3 "$CH_DIR/var/lib/audiobible/english/"
	sed -e "s/%PKG%/${pkg}/g" -e "s/%VERSION%/${ver}/g" \
	    -e "s/%BOOK%/${book}/g" -e "s/%CHAPTER%/${chapter}/g" \
	    packaging/deb/control-chapter > "$CH_DIR/DEBIAN/control"
	dpkg-deb --build --root-owner-group "$CH_DIR" "${pkg}_${ver}_all.deb"
	echo "Built ${pkg}_${ver}_all.deb"

	DEPENDS="${DEPENDS}${DEPENDS:+, }${pkg} (= ${ver})"
done

META_VERSION="0.$(git rev-list --count HEAD)"
META_DIR="$PKG_DIR/audiobible-darkknox2-english"
mkdir -p "$META_DIR/DEBIAN"
sed -e "s/^Version: .*/Version: ${META_VERSION}/" packaging/deb/control \
    | sed "/^Architecture:/a Depends: ${DEPENDS}" > "$META_DIR/DEBIAN/control"
dpkg-deb --build --root-owner-group "$META_DIR" "audiobible-darkknox2-english_${META_VERSION}_all.deb"

rm -rf "$PKG_DIR"
echo "Built audiobible-darkknox2-english_${META_VERSION}_all.deb (meta package)"
