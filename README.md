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
podman run --name openwrt -it -u user -v $(pwd)/openwrt-builder:/home/user/openwrt-builder:z,rw quay.io/dpawlik/openwrt:f38 bash
```

Then inside the container (from https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem):

```shell
git clone https://git.openwrt.org/openwrt/openwrt.git ~/openwrt-builder/openwrt && cd ~/openwrt-builder/openwrt
```

Optionally add MediaTek feed:

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

If you have own config file, replace it. For example:

```shell
# for BPI-R4
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/mediatek/mt7988a/extended > ~/openwrt-builder/openwrt/.config
# for AX3200
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/mediatek/mt7622/extended > ~/openwrt-builder/openwrt/.config
# or official
curl -SL https://downloads.openwrt.org/snapshots/targets/mediatek/mt7622/config.buildinfo > ~/openwrt-builder/openwrt/.config

### alternative configs ###
# Xiaomi 4A Giga Edition
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/ramips/mt7621/extended > ~/openwrt-builder/openwrt/.config
# AX3600
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/qualcommax/ax3600/extended > ~/openwrt-builder/openwrt/.config
```

## Build

Configure the firmware image and the kernel:

```shell
make menuconfig
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

## With Ansible - WIP

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
