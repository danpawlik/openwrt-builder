#!/bin/bash

CURRENT_DIR=$(pwd)
DEFCONFIG=$CURRENT_DIR/openwrt-mediatek/mtk-openwrt-feeds/autobuild/unified/filogic/master/defconfig
OTHER_CONFIG=$CURRENT_DIR/openwrt-mediatek/mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
TEMP_CONFIG=$CURRENT_DIR/openwrt-mediatek/myconfig
MAIN_CONFIG=$CURRENT_DIR/openwrt-mediatek/.config

git clone https://git.openwrt.org/openwrt/openwrt.git openwrt-mediatek || true
cd openwrt-mediatek
git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true

echo '# CONFIG_IXGBEVF_IPSEC is not set' >> target/linux/generic/config-6.6
echo '# CONFIG_IXGBE_IPSEC is not set' >> target/linux/generic/config-6.6
echo '# CONFIG_RTL8261N_PHY is not set' >> target/linux/generic/config-6.6

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
CONFIG_PACKAGE_mt7988-wo-firmware=y
EOF

make defconfig
grep "=m" .config | grep -v 'CONFIG_PACKAGE_libustream-mbedtls=m' | while read -r line; do module=$(echo "$line" | cut -f1 -d'='); sed -i "s/^$line$/# $module is not set/" .config; done
sed -i 's/CONFIG_PACKAGE_kmod-crypto-eip=y/# CONFIG_PACKAGE_kmod-crypto-eip is not set/g' $MAIN_CONFIG
make -j$(nproc) defconfig clean download world

## to clean - each time after run prepare:
# git reset --hard
# git clean -f -d
# bash ./mtk-openwrt-feeds/autobuild/unified/autobuild.sh clean
