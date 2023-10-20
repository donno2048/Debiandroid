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
    ar x $pkg $(ar t $pkg | grep data)
    proot --link2symlink tar faox data.*
    rm -f data.*
done
echo "nameserver 8.8.8.8
nameserver 8.8.4.4" > $PWD/etc/resolv.conf
echo "root:x:0:0:root:/:/bin/sh
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
_apt:x:100:65534::/nonexistent:/usr/sbin/nologin" > $PWD/etc/passwd
echo "Package: dpkg
Version: $(dpkg-deb -f $(ls $PWD/var/cache/apt/archives/dpkg*.deb -1) Version)
Maintainer: unknown
Status: install ok installed" > $PWD/var/lib/dpkg/status
echo "deb http://deb.debian.org/debian bullseye main" > $PWD/etc/apt/sources.list
