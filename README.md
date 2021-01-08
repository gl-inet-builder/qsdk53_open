## compile

This command is for Debian/Ubuntu; it must be customized for other distributions:
```
sudo apt-get install gcc g++ binutils patch bzip2 flex make gettext \
pkg-config unzip zlib1g-dev libc6-dev subversion libncurses5-dev gawk \
sharutils curl libxml-parser-perl ocaml-nox ocaml-nox ocaml ocaml-findlib \
libpcre3-dev binutils-gold python-yaml device-tree-compiler
```

This command is for Ubuntu 16.04.3 64 bit build hosts:
```
sudo apt-get install gcc g++ binutils patch bzip2 flex make gettext pkgconfig \
unzip zlib1g-dev libc6-dev subversion libncurses5-dev gawk sharutils \
curl libxml-parser-perl ocaml-nox ocaml ocaml-findlib libpcre3-dev \
binutils-gold python-yaml libgl1-mesa-dri:i386 libgd-dev multiarch-support \
lib32ncurses5 lib32z1 libssl-dev device-tree-compiler
```

```
./scripts/feeds update -a
./scripts/feeds install -a -f
cp ipq806x_custom.config .config
make defconfig
make menuconfig     # keep Target Profile premium profile
tar xf dl.tar.bz2
make V=s
make si V=s         # single image
```

## compile output
single_img_dir/ipq40xx-nor-apps.img
  - firmware with kernel and rootfs

single_img_dir/nor-ipq40xx-single.img
  - firmware with all partitions including uboot, kernel and rootfs etc.

In bin directory:
openwrt-ipq40xx-u-boot-stripped.elf (Bootloader)
openwrt-ipq806x-qcom-ipq40xx-ap.dkxx-fit-uImage.itb (Kernel + dtb)
openwrt-ipq806x-squashfs-root.img (SquashFS)

## flashing
- Method 1. setup tftpd server and issue uboot command:
```
run lfq
```

- Method 2. setup tftpd server and issue uboot command:
```
setenv serverip 192.168.1.2
tftpboot 0x84000000 nor-ipq40xx-single.img
sf probe && imgaddr=0x84000000 && source $imgaddr:script
```

- Method 3. uboot web
power on with reset button pressed for more than 8 seconds till
the middle light being constant on and goto http://192.168.1.1

## for wifi test:
```
uci set wireless.@wifi-device[0].disabled=0
uci set wireless.@wifi-device[1].disabled=0
uci set wireless.@wifi-iface[0].ssid='OpenWrt-2g'
uci set wireless.@wifi-iface[1].ssid='OpenWrt-5g'
uci set wireless.@wifi-device[0].txpower='20'
uci set wireless.@wifi-device[1].txpower='20'
uci set wireless.@wifi-device[0].htmode=HT40
uci set wireless.@wifi-iface[0].disablecoext='1'
uci commit
wifi
```

## imagebuilder
```
cd OpenWrt-ImageBuilder-ipq806x.Linux-x86_64
make image PROFILE="QSDK_Premium"
make si
```
then
use single_img_dir/ipq40xx-nor-apps.img to do firmware upgrade, which include kernel and rootfs.
