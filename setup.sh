#!/bin/bash
#set -e
export PATH LANG=C
unset LD_PRELOAD TMPDIR
mkdir -p $PWD/etc/apt
mkdir -p $PWD/var/lib/dpkg/info
mkdir -p $PWD/var/lib/apt/lists/partial
mkdir -p $PWD/var/cache/apt/archives/partial
mkdir -p $PWD/usr/sbin
mkdir -p $PWD/usr/bin
mkdir -p $PWD/sbin
touch $PWD/var/lib/dpkg/available
touch $PWD/etc/fstab
touch $PWD/var/lib/dpkg/info/dpkg.list
ln -sf /usr/share/zoneinfo/UTC $PWD/etc/localtime
echo "deb http://deb.debian.org/debian bullseye main" > $PWD/etc/apt/sources.list
export CFLAGS="-static"
case $(uname -m) in
        arm) ARCH=armel;;
        aarch64) ARCH=arm64;;
        i686) ARCH=i386;;
        x86_64) ARCH=amd64;;
esac
for pkg in $(cat packages.txt | sed "s/ARCH/$ARCH/g"); do
    wget -nv -nd https://ftp.debian.org/debian/$pkg
done
wget -nv -qO- http://deb.debian.org/debian/dists/bullseye/main/binary-$ARCH/Packages.gz | gunzip - -c > $PWD/var/lib/apt/lists/deb.debian.org_dists_bullseye_main_binary-${ARCH}_Packages
wget -nv -r -nd --no-parent -A mawk_*_$ARCH.deb https://ftp.debian.org/debian/pool/main/m/mawk/
rm -f $(ls mawk*.deb -1 -r | sed -n '1d;p')
for pkg in *.deb; do
    dpkg-deb --fsys-tarfile $pkg | proot --link2symlink tar -xf -
done
mv *.deb $PWD/var/cache/apt/archives
echo "Package: dpkg
Version: $(dpkg-deb -f $(ls $PWD/var/cache/apt/archives/dpkg*.deb -1) Version)
Maintainer: unknown
Status: install ok installed" > $PWD/var/lib/dpkg/status
termux-chroot $PWD/sbin/ldconfig
export DEBIAN_FRONTEND=noninteractive DEB_CONF_NONINTERACTIVE_SEEN=true
ln -sf mawk $PWD/usr/bin/awk
rm $PWD/usr/bin/awk
base="base-passwd base-files libc6 perl-base mawk libselinux1 libpcre2-8-0 dpkg"
for pkg in $base; do
    rm -rf tempo
    yes | proot --link2symlink dpkg-deb -R $PWD/var/cache/apt/archives/${pkg}_*.deb tempo
    rm -f tempo/DEBIAN/post*
    sed -i -e 's/dpkg-maintscript-helper/#/g' tempo/DEBIAN/pre* || true
    yes | dpkg-deb -b tempo $pkg.deb
    if [ "$pkg" != "dpkg" ]; then
        termux-chroot dpkg --force-all --install $pkg.deb
        rm $pkg.deb
    fi
done
rm -rf tempo
for pkg in $PWD/var/cache/apt/archives/*.deb; do
    ar x $pkg $(ar t $pkg | grep data)
    proot --link2symlink tar faox data.*
    rm -f data.*
done
echo "
#!/bin/bash
exit 101" > $PWD/usr/sbin/policy-rc.d
chmod +x $PWD/usr/sbin/policy-rc.d
mv $PWD/sbin/start-stop-daemon $PWD/sbin/start-stop-daemon.REAL
touch $PWD/sbin/start-stop-daemon
chmod +x $PWD/sbin/start-stop-daemon
echo "nameserver 8.8.8.8
nameserver 8.8.4.4" > $PWD/etc/resolv.conf
echo "apt apt" > $PWD/var/lib/dpkg/cmethopt
chmod +x $PWD/var/lib/dpkg/cmethopt
export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin
termux-chroot dpkg --configure --pending --force-configure-any --force-depends --force-architecture
ls var/cache/apt/archives/ -1 | grep -oP "^[^/_]*(?=_)" | grep -vE "^($(echo $base | tr ' ' '|'))$" > not_installed
while [ ! -z "$(<not_installed)" ]; do
    echo > to_install
    for pkg in $(<not_installed); do
        if [ -z "$(dpkg-deb -I $PWD/var/cache/apt/archives/${pkg}_*.deb | grep -E "Depends|Pre-Depends" | tr " " "\n" | grep -oP ".*[^,]" | fgrep -Fxf not_installed)" ]; then
                echo $pkg >> to_install
        fi
    done
    cat not_installed | grep -vE "^($(printf "$(awk NF to_install | sort | uniq | sed 's/[.[\(*^$+?{|]/\\&/g')" | tr '\n' '|'))$" > not_installed
    for pkg in $(<to_install); do
         env -u LD_PRELOAD proot -S . --link2symlink /usr/bin/dpkg --force-overwrite --force-confold --force-depends --force-architecture --skip-same-version --install $PWD/var/cache/apt/archives/${pkg}_*.deb
    done
done
rm not_installed
rm to_install
termux-chroot dpkg --force-all --install dpkg.deb
rm dpkg.deb
mv $PWD/sbin/start-stop-daemon.REAL $PWD/sbin/start-stop-daemon
rm -f $PWD/usr/sbin/policy-rc.d
echo "root:x:0:
mail:x:8:
shadow:x:42:
utmp:x:43:" > etc/group
echo "root:x:0:0:root:/:/bin/sh
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
_apt:x:100:65534::/nonexistent:/usr/sbin/nologin" > etc/passwd
