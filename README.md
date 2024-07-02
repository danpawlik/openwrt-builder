# Openwrt
Build OpenWRT system image

## How to

Container image to build Openwrt image based on https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem
To build own container image:

```shell
sudo yum install -y git podman
git clone https://github.com/danpawlik/openwrt-builder
cd openwrt-builder
podman build -t openwrt-builder -f Dockerfile
```

## Example config

How to use:

```shell
mkdir -p openwrt-builder && chmod 0777 openwrt-builder
podman run --name openwrt -it -u user -v $(pwd)/openwrt-builder:/home/user/openwrt-builder:z,rw quay.io/dpawlik/openwrt:f40 bash
```

Then inside the container (from https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem):

```shell
git clone https://git.openwrt.org/openwrt/openwrt.git ~/openwrt-builder/openwrt && cd ~/openwrt-builder/openwrt
```

Optionally add MediaTek feed (onlt for 21.02):

```shell
cat << EOF >> feeds.conf.default
src-git mtksdk https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds
EOF
git add feeds.conf.default ; git commit -m 'Add MediaTek feed'
```

Update the feeds:

```shell
./scripts/feeds update -a && ./scripts/feeds install -a
```

Use device config:

```shell
# BPI-R4
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/mediatek/mt7988a/bpi-r4 > ~/openwrt-builder/openwrt/.config

# AX3200
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/mediatek/mt7622/ax3200 > ~/openwrt-builder/openwrt/.config

# AX3600
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/qualcommax/ax3600 > ~/openwrt-builder/openwrt/.config

# Xiaomi 4A Giga Edition
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/ramips/mt7621/4a-giga > ~/openwrt-builder/openwrt/.config

# Ubiquiti U6 Lite
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/ramips/mt7621/u6-lite > ~/openwrt-builder/openwrt/.config

# Ubuquti UAP-AC-LR
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/ath79/generic/uap-ac-lr > ~/openwrt-builder/openwrt/.config

# Mikrotik hAP AC
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/ath79/mikrotik/962uigs-5hact2hnt > ~/openwrt-builder/openwrt/.config
```

NOTE: If device got additional hardware installed, for example: Banana Pi R4 got wireless card,
it is also included in the config file.

then add the required packages that I use for the router/AP function:

* Main router:
```shell
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/main-router >> ~/openwrt-builder/openwrt/.config
```

* Dumb AP:

```shell
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/dumb_ap >> ~/openwrt-builder/openwrt/.config
```

* Basic config

```shell
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/basic >> ~/openwrt-builder/openwrt/.config
```

## Build

Configure the firmware image and the kernel:

```shell
make menuconfig

# or

./scripts/diffconfig.sh > diffconfig
cp diffconfig .config
make defconfig
```

Optional: comment modules:

```shell
for m in $(grep "=m" .config | grep -v 'CONFIG_PACKAGE_libustream-mbedtls=m'); do module=$(echo $m| cut -f1 -d'='); sed -i "s/$m/\# $module is not set/g" .config; done
# or
grep "=m" .config | grep -v 'CONFIG_PACKAGE_libustream-mbedtls=m' | while read -r line; do module=$(echo "$line" | cut -f1 -d'='); sed -i "s/^$line$/# $module is not set/" .config; done
```

Then:

```shell
make -j$(nproc) kernel_menuconfig
```

Build the firmware image:

```shell
make -j $(nproc) defconfig download clean world
```

To get more verbosity:

```shell
make -j1 V=s defconfig download clean world
```

## Example workflow

```shell
# Banana Pi R4 as main router
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/mediatek/mt7988a/bpi-r4 > ~/openwrt-builder/openwrt/.config
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/main-router >> ~/openwrt-builder/openwrt/.config
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/optimize >> ~/openwrt-builder/openwrt/.config
./scripts/diffconfig.sh > diffconfig
cp diffconfig .config
make defconfig
for m in $(grep "=m" ~/openwrt-builder/openwrt/.config | grep -v 'CONFIG_PACKAGE_libustream-mbedtls=m'); do module=$(echo $m| cut -f1 -d'=');  sed -i "s/$m/\# $module is not set/g" ~/openwrt-builder/openwrt/.config;  done
make -j$(nproc) kernel_menuconfig
make -j $(nproc) defconfig download clean world

# AX3200 as dumb AP
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/mediatek/mt7622/ax3200 > ~/openwrt-builder/openwrt/.config
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/dumb_ap >> ~/openwrt-builder/openwrt/.config
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/optimize >> ~/openwrt-builder/openwrt/.config
./scripts/diffconfig.sh > diffconfig
cp diffconfig .config
make defconfig
for m in $(grep "=m" ~/openwrt-builder/openwrt/.config | grep -v 'CONFIG_PACKAGE_libustream-mbedtls=m'); do module=$(echo $m| cut -f1 -d'=');  sed -i "s/$m/\# $module is not set/g" ~/openwrt-builder/openwrt/.config;  done
make -j$(nproc) kernel_menuconfig
make -j $(nproc) defconfig download clean world
```

## With Ansible - WIP (Work In Progress)

* Install Ansible:

```sh
sudo dnf install -y ansible-core git
```

* Clone builder project

```sh
git clone https://github.com/danpawlik/openwrt-builder && cd openwrt-builder
```

* Run Ansible playbook

```sh
ansible-playbook -i ansible/inventory.yaml ansible/openwrt-build.yaml
```
