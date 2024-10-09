#!/bin/bash

CURRENT_DIR=$(pwd)
DEFCONFIG=$CURRENT_DIR/openwrt-mediatek/mtk-openwrt-feeds/autobuild/unified/filogic/master/defconfig
OTHER_CONFIG=$CURRENT_DIR/openwrt-mediatek/mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
TEMP_CONFIG=$CURRENT_DIR/openwrt-mediatek/myconfig

echo $DEFCONFIG
##exit 0

git clone https://git.openwrt.org/openwrt/openwrt.git openwrt-mediatek || true
cd openwrt-mediatek
git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true

echo 'CONFIG_IXGBEVF_IPSEC=y' >> target/linux/generic/config-6.6
echo 'CONFIG_IXGBE_IPSEC=y' >> target/linux/generic/config-6.6
echo 'CONFIG_RTL8261N_PHY=m' >> target/linux/generic/config-6.6


curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/mediatek/mt7988a/bpi-r4 > $DEFCONFIG

# From mediatek feed defconfig $DEFCONFIG
cat << EOF >> $DEFCONFIG
CONFIG_PACKAGE_kmod-ata-core=y
CONFIG_PACKAGE_kmod-scsi-generic=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-msdos=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_kmod-hwmon-pwmfan=y
CONFIG_PACKAGE_kmod-i2c-gpio=y
CONFIG_PACKAGE_kmod-i2c-mux-pca954x=y
CONFIG_PACKAGE_kmod-ipt-conntrack=y
CONFIG_PACKAGE_kmod-ipt-extra=y
CONFIG_PACKAGE_kmod-ipt-nat=y
CONFIG_PACKAGE_kmod-ipt-offload=y
CONFIG_PACKAGE_kmod-phy-airoha-en8811h=y
CONFIG_PACKAGE_kmod-eeprom-at24=y
CONFIG_PACKAGE_kmod-rtc-pcf8563=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-mt7996-firmware=y
CONFIG_PACKAGE_strongswan=y
EOF

curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/main-router > $TEMP_CONFIG
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/snapshot-short >> $TEMP_CONFIG
sed -i '/CONFIG_PACKAGE_wpad-mbedtls=y/d' $TEMP_CONFIG
curl -SL https://raw.githubusercontent.com/danpawlik/openwrt-builder/master/configs/common/openssl >> $TEMP_CONFIG

# FIXME: Should CONFIG_PACKAGE_strongswan-default=y CONFIG_PACKAGE_strongswan=y  be added?
# Temporary commented: CONFIG_PACKAGE_kmod-crypto-eip=y
for v in $(grep '=y' $TEMP_CONFIG | grep -v '#') CONFIG_PACKAGE_kmod-crypto-eip197; do
	name=$(echo $v | cut -f1 -d'=') ;
	sed -i "s|# $name is not set|$v|" $OTHER_CONFIG
done

sed -i 's/CONFIG_PACKAGE_kmod-crypto-eip=y/# CONFIG_PACKAGE_kmod-crypto-eip is not set/g' $OTHER_CONFIG
sed -i 's/CONFIG_PACKAGE_kmod-crypto-eip197/# CONFIG_PACKAGE_kmod-crypto-eip197 is not set/g' $OTHER_CONFIG


bash ./mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-BE19000 log_file=make

# when it fails
# cd openwrt-mediatek
# grep "=m" .config | grep -v 'CONFIG_PACKAGE_libustream-mbedtls=m' | while read -r line; do module=$(echo "$line" | cut -f1 -d'='); sed -i "s/^$line$/# $module is not set/" .config; done
# make defconfig clean download world
#
# alternative
# cd openwrt-mediatek
# git clean -f -d
# bash ./mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-BE19000 log_file=make
