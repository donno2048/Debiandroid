#!/bin/bash
set -e
apt="env -u TMPDIR -u LD_PRELOAD -u PATH proot --link2symlink -S . /usr/bin/apt"
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
mkdir usr/local
ln -sf /usr/share/zoneinfo/UTC etc/localtime
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > etc/resolv.conf
echo -e "root:x:0:0:root:/:/bin/sh\n_apt:x:100:65534::/nonexistent:/usr/sbin/nologin\nuucp:x:10:10:uucp:/var/spool/uucp:/bin/sh\nmail:x:8:8:mail:/var/mail:/bin/sh" > etc/passwd
echo -e "Package: dpkg\nVersion: $(dpkg-deb -f $(ls $packages_path/dpkg*.deb) Version)\nMaintainer: unknown\nStatus: install ok installed" > var/lib/dpkg/status
echo -e "alias debian='env -u TMPDIR -u LD_PRELOAD -u PATH proot --link2symlink -S . -w /root /bin/bash'\nexport PATH\nexport GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'\nexport PS1='\[\033[01;32m\]\u\[\033[00m\]@\[\033[01;34m\]\w\[\033[00m\]$ '\nalias ls='ls --color=auto --group-directories-first'\nalias grep='grep --color=auto'\nalias dir='dir --color=auto'\nalias diff='diff --color=auto'\nexport LC_ALL=C\nexport DEBIAN_FRONTEND=readline" >> ~/.bashrc
echo -e "root:x:0:\nstaff:x:1:\nuucp:x:10:\nmail:x:8:mail\nadm:x:4:" >> etc/group
echo "deb http://deb.debian.org/debian bullseye main" > etc/apt/sources.list
$apt update
$apt install mawk -y
rm "$0"
