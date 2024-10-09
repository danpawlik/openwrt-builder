#!/bin/bash

CURRENT_DIR=$(pwd)
DEFCONFIG=$CURRENT_DIR/openwrt-mediatek/mtk-openwrt-feeds/autobuild/unified/filogic/master/defconfig
OTHER_CONFIG=$CURRENT_DIR/openwrt-mediatek/mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
TEMP_CONFIG=$CURRENT_DIR/openwrt-mediatek/myconfig
MAIN_CONFIG=$CURRENT_DIR/openwrt-mediatek/.config

git clone https://git.openwrt.org/openwrt/openwrt.git openwrt-mediatek || true
cd openwrt-mediatek
git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true

echo 'CONFIG_IXGBEVF_IPSEC=y' >> target/linux/generic/config-6.6
echo 'CONFIG_IXGBE_IPSEC=y' >> target/linux/generic/config-6.6
echo 'CONFIG_RTL8261N_PHY=m' >> target/linux/generic/config-6.6

curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/mediatek/mt7988a/bpi-r4 > "$DEFCONFIG"

curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/main-router > "$TEMP_CONFIG"
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/snapshot-short >> "$TEMP_CONFIG"
sed -i '/CONFIG_PACKAGE_wpad-mbedtls=y/d' "$TEMP_CONFIG"
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/openssl >> "$TEMP_CONFIG"

# FIXME: Should CONFIG_PACKAGE_strongswan-default=y CONFIG_PACKAGE_strongswan=y  be added?
# Temporary commented: CONFIG_PACKAGE_kmod-crypto-eip=y
for v in $(grep '=y' "$TEMP_CONFIG" | grep -v '#') CONFIG_PACKAGE_kmod-crypto-eip197; do
	name=$(echo "$v" | cut -f1 -d'=') ;
	sed -i "s|# $name is not set|$v|" "$OTHER_CONFIG"
done

sed -i 's/CONFIG_PACKAGE_kmod-crypto-eip=y/# CONFIG_PACKAGE_kmod-crypto-eip is not set/g' "$OTHER_CONFIG"
sed -i 's/CONFIG_PACKAGE_kmod-crypto-eip197/# CONFIG_PACKAGE_kmod-crypto-eip197 is not set/g' "$OTHER_CONFIG"

# Run prepare instead of build
bash ./mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-BE19000 prepare log_file=make

# To build via mtk feed:
# bash ./mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-BE19000 log_file=make

# It will fail, so let's re-use packages set in Mediatek feed + my packages
# and make world!

curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/mediatek/mt7988a/bpi-r4 > "$MAIN_CONFIG"
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/main-router >> "$MAIN_CONFIG"
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/snapshot-short >> "$MAIN_CONFIG"
sed -i '/CONFIG_PACKAGE_wpad-mbedtls=y/d' "$MAIN_CONFIG"
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/openssl >> "$MAIN_CONFIG"

cat << EOF >> "$MAIN_CONFIG"
CONFIG_PACKAGE_bridger=y
CONFIG_PACKAGE_airoha-en8811h-firmware=y
CONFIG_PACKAGE_aqr10g-phy-firmware=y
CONFIG_PACKAGE_mt7988-wo-firmware=y
CONFIG_PACKAGE_kmod-ata-core=y
CONFIG_PACKAGE_kmod-scsi-core=y
CONFIG_PACKAGE_kmod-scsi-generic=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-msdos=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-i2c-algo-bit=y
CONFIG_PACKAGE_kmod-i2c-gpio=y
CONFIG_PACKAGE_kmod-lib-crc16=y
CONFIG_PACKAGE_kmod-nls-cp437=y
CONFIG_PACKAGE_kmod-nls-iso8859-1=y
CONFIG_PACKAGE_kmod-nls-utf8=y
CONFIG_PACKAGE_kmod-ipt-conntrack=y
CONFIG_PACKAGE_kmod-ipt-conntrack-extra=y
CONFIG_PACKAGE_kmod-ipt-extra=y
CONFIG_PACKAGE_kmod-ipt-nat=y
CONFIG_PACKAGE_kmod-ipt-offload=y
CONFIG_PACKAGE_kmod-nf-conncount=y
CONFIG_PACKAGE_kmod-phy-airoha-en8811h=y
CONFIG_PACKAGE_kmod-sched-act-vlan=y
CONFIG_PACKAGE_kmod-sched-bpf=y
CONFIG_PACKAGE_kmod-sched-flower=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-mt76=y
CONFIG_PACKAGE_kmod-mt7603=y
CONFIG_PACKAGE_kmod-mt76x02-common=y
CONFIG_PACKAGE_kmod-mt76x2=y
CONFIG_PACKAGE_kmod-mt76x2-common=y
CONFIG_PACKAGE_iptables-mod-conntrack-extra=y
CONFIG_PACKAGE_hostapd-utils=y
CONFIG_PACKAGE_wpa-cli=y
CONFIG_PACKAGE_iw-full=y
EOF

make defconfig
grep "=m" .config | grep -v 'CONFIG_PACKAGE_libustream-mbedtls=m' | while read -r line; do module=$(echo "$line" | cut -f1 -d'='); sed -i "s/^$line$/# $module is not set/" .config; done
make -j$(nproc) defconfig clean download world

## to clean:
# git reset --hard
# git clean -f -d
# bash ./mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-BE19000 log_file=make
