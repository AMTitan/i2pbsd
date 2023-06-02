# i2pbsd
A live bootable OpenBSD distro to use i2p

NOT FULLY WORKING AS OF YET

## Building

You will need

- ~5gb of free space
- a openbsd system (or vm)

In a new openbsd system (If you used the default install you will need to go to `/home` to have enough storage) or an existing one run the following:

```sh
pkg_add git
git clone https://github.com/amtitan/i2pbsd
cd i2pbsd
chmod +x build.sh
./build.sh
```

You should now have the file `i2pbsd.iso` that you are able to plugin to any system to get i2p up and running securly
