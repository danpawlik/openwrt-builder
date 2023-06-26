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

## Example

how to use:

```shell
mkdir -p openwrt-builder
chmod 0777 openwrt-builder
podman run -it -u user -v $(pwd)/openwrt-builder/:/home/user:z,rw quay.io/dpawlik/openwrt:f38 /bin/bash
```

Then inside the container (from https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem):

```shell
git clone https://git.openwrt.org/openwrt/openwrt.git
cd openwrt
git pull
```

Select a specific code revision:

```shell
git branch -a
git tag
git checkout v23.05.0-rc1
```

Update the feeds:

```shell
./scripts/feeds update -a
./scripts/feeds install -a
```

Configure the firmware image and the kernel:

```shell
make menuconfig
```

If you have own config file, replace it. For example:

```shell
curl -SL https://downloads.openwrt.org/snapshots/targets/ath79/mikrotik/config.buildinfo > .config
```

Then:

```shell
# make kernel_menuconfig
make -j4 kernel_menuconfig
```

Build the firmware image:

```shell
make -j $(nproc) defconfig download clean world
```

## With Ansible

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
