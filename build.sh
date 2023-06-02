#!/bin/ksh

set -x

arch="amd64"
version="7.3"

version_no_dot=$(printf "$version" | tr -d '.')

pkg_add wget curl cdrtools jq

wget -nc "https://cdn.openbsd.org/pub/OpenBSD/$version/$arch/install$version_no_dot.iso"
mkdir tmp_build
vnconfig vnd0 "install$version_no_dot.iso"
mount /dev/vnd0a tmp_build
mkdir build
cp -r tmp_build/* build
umount tmp_build
vnconfig -u vnd0

cd tmp_build
cp ../build/$version/$arch/bsd.rd ./bsd.rd.gz
gzip -d ./bsd.rd.gz
rdsetroot -x bsd.rd disk.fs
vnconfig vnd0 disk.fs
mkdir mount
mount /dev/vnd0a mount

rm mount/{install,install.md,install.sub,upgrade,autoinstall}

echo "
#!/bin/ksh

sleep 3

rootdisk=\$(dmesg | sed -E '/^root on ([^ ]+) .*$/h;\$!d;g;s//\1/')
mount -u /dev/\${rootdisk:-rd0a} /

mount /dev/cd0a /mnt

export LD_LIBRARY_PATH=/lib
ln -s /mnt/$version/$arch/i2pbsd/lib /lib
ln -s /mnt/$version/$arch/i2pbsd/usr/lib /usr/lib
ln -s /mnt/$version/$arch/i2pbsd/usr/libexec /usr/libexec

/mnt/$version/$arch/i2pbsd/bin/i2pd & /mnt/$version/$arch/i2pbsd/librewolf/librewolf-bin

" > mount/.profile

mkdir ../build/$version/$arch/i2pbsd
cd mount
tar -czf ../disk.tgz .
cd ..
tar -C ../build/$version/$arch/i2pbsd -xzf disk.tgz

umount mount
vnconfig -u vnd0

rdsetroot bsd.rd disk.fs
gzip bsd.rd
mv bsd.rd.gz ../build/$version/$arch/bsd.rd

cd ../build/$version/$arch/

tar -C i2pbsd -xzf ./base$version_no_dot.tgz 
tar -C i2pbsd -xzf ./comp$version_no_dot.tgz 
tar -C i2pbsd -xzf ./xbase$version_no_dot.tgz 
tar -C i2pbsd -xzf ./xfont$version_no_dot.tgz 
tar -C i2pbsd -xzf ./xserv$version_no_dot.tgz

libversion=$(curl "https://gitlab.com/librewolf-community/browser/source/-/releases.json" | jq -r '.[0]|.tag')

wget https://gitlab.com/api/v4/projects/44042130/packages/generic/librewolf/$libversion/librewolf-$libversion-linux-x86_64-package.tar.bz2

tar -C i2pbsd -xf librewolf-$libversion-linux-x86_64-package.tar.bz2

rm librewolf-$libversion-linux-x86_64-package.tar.bz2

printf "i2pd\n" | while read package; do
  name="$(pkg_info -f "$package" | grep "@name" | cut -f 2 -d " ")"
  wget "http://cdn.openbsd.org/pub/OpenBSD/$version/packages/$arch/$name.tgz"
  tar -C i2pbsd -xzf "$name.tgz"

  pkg_info -f "$package" | grep '@depend' | cut -f 3 -d : | while read package; do
    wget "http://cdn.openbsd.org/pub/OpenBSD/$version/packages/$arch/$package.tgz"
    tar -C i2pbsd -xzf "$package.tgz"
  done
done

rm ./*.tgz

cd ../../..

mkisofs -r -no-emul-boot -b $version/$arch/cdbr -c boot.catalog -o i2pbsd.iso build
