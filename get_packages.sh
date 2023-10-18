#!/bin/bash
echo > packages.txt
allpackages="apt $(dpkg-query -Wf '${Package} ${Essential}\n' | grep yes | awk '{print $1}')"
while [ "$allpackages" != "$packages" ]; do
    packages=$allpackages
    allpackages=$(echo $packages $(apt-cache depends -i $packages | awk '{print $2}' | sort | uniq | grep '^[^\<]') | tr ' ' '\n' | sort | uniq)
done
for pkg in $allpackages; do
    apt-cache show $pkg | grep -oP "Filename:\s\K.*" >> packages.txt
done
