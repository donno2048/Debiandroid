#!/bin/bash
set -e
case $(uname -m) in
        arm) ARCH=armel;;
        aarch64) ARCH=arm64;;
        i686) ARCH=i386;;
        x86_64) ARCH=amd64;;
esac
packages_path="var/cache/apt/archives"
for pkg in $(wget -qO- https://raw.githubusercontent.com/donno2048/Debiandroid/master/packages.txt | sed "s/ARCH/$ARCH/g"); do
    wget -nv -nd https://ftp.debian.org/debian/$pkg -P $packages_path
    path="$packages_path/$(grep -o '[^/]*\.deb' <<< $pkg)"
    ar x $path $(ar t $path | grep data)
    proot --link2symlink tar faox data.*
    rm -f data.*
done
ln -sf /usr/share/zoneinfo/UTC etc/localtime
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > etc/resolv.conf
echo -e "root:x:0:0:root:/:/bin/sh\n_apt:x:100:65534::/nonexistent:/usr/sbin/nologin" > etc/passwd
echo -e "Package: dpkg\nVersion: $(dpkg-deb -f $(ls $packages_path/dpkg*.deb) Version)\nMaintainer: unknown\nStatus: install ok installed" > var/lib/dpkg/status
echo "deb http://deb.debian.org/debian bullseye main" > etc/apt/sources.list
echo "alias debian='env -u TMPDIR -u LD_PRELOAD -u PATH proot --link2symlink -S . -w /root /bin/bash'" >> ~/.bashrc
