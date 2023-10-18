#!/bin/bash
echo > packages.txt
case $(uname -m) in
        arm) ARCH=armel;;
        aarch64) ARCH=arm64;;
        i686) ARCH=i386;;
        x86_64) ARCH=amd64;;
        *) ARCH=$(uname -p);;
esac
allpackages="apt $(dpkg-query -Wf '${Package} ${Essential}\n' | grep yes | awk '{print $1}')"
while [ "$allpackages" != "$packages" ]; do
    packages=$allpackages
    allpackages=$(echo $packages $(apt-cache depends -i $packages | awk '{print $2}' | sort | uniq | grep '^[^\<]') | tr ' ' '\n' | sort | uniq)
done
for pkg in $allpackages; do
    apt-cache show $pkg | grep -oP "Filename:\s\K.*" | sed "s/$ARCH/ARCH/g" >> packages.txt
done
