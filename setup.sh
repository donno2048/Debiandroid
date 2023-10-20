#!/bin/bash
set -e
case $(uname -m) in
        arm) ARCH=armel;;
        aarch64) ARCH=arm64;;
        i686) ARCH=i386;;
        x86_64) ARCH=amd64;;
esac
for pkg in $(wget -qO- https://raw.githubusercontent.com/donno2048/Debiandroid/master/packages.txt | sed "s/ARCH/$ARCH/g"); do
    wget -nv -nd https://ftp.debian.org/debian/$pkg -P $PWD/var/cache/apt/archives
done
for pkg in $PWD/var/cache/apt/archives/*.deb; do
    dpkg-deb --fsys-tarfile $pkg | proot --link2symlink tar -xf -
done
for pkg in base-passwd base-files libc6 perl-base libselinux1 libpcre2-8-0 dpkg; do
    proot --link2symlink dpkg-deb -R $PWD/var/cache/apt/archives/${pkg}_*.deb tempo
    rm -f tempo/DEBIAN/post*
    sed -i -e 's/dpkg-maintscript-helper/#/g' tempo/DEBIAN/pre* || true
    dpkg-deb -b tempo $pkg.deb
    if [ "$pkg" != "dpkg" ]; then
        termux-chroot dpkg --force-all --install $pkg.deb
        rm $pkg.deb
    fi
    rm -rf tempo
done
for pkg in $PWD/var/cache/apt/archives/*.deb; do
    ar x $pkg $(ar t $pkg | grep data)
    proot --link2symlink tar faox data.*
    rm -f data.*
done
echo "nameserver 8.8.8.8
nameserver 8.8.4.4" > $PWD/etc/resolv.conf
termux-chroot dpkg --configure --pending --force-configure-any --force-depends --force-architecture
echo "root:x:0:
mail:x:8:
shadow:x:42:
utmp:x:43:" > $PWD/etc/group
echo "root:x:0:0:root:/:/bin/sh
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
_apt:x:100:65534::/nonexistent:/usr/sbin/nologin" > $PWD/etc/passwd
echo "Package: dpkg
Version: $(dpkg-deb -f $(ls $PWD/var/cache/apt/archives/dpkg*.deb -1) Version)
Maintainer: unknown
Status: install ok installed" > $PWD/var/lib/dpkg/status
echo "deb http://deb.debian.org/debian bullseye main" > $PWD/etc/apt/sources.list
termux-chroot dpkg --force-all --install dpkg.deb
rm dpkg.deb
