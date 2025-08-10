#!/bin/bash

# Example usage:
# ./openwrt-configure.sh 192.168.88.1 main
# ./openwrt-configure.sh 192.168.88.2
#
## or extended
# SPEEDTEST_TOOLS=librespeed-go ./openwrt-configure.sh 192.168.88.1 main

ROUTER_IP="${ROUTER_IP=$1}"
# DEVICE can be main or <nothing>
DEVICE="${DEVICE:-$2}"
FULL_WPAD="${FULL_WPAD:-'true'}"
INSTALL_BRIDGER=${INSTALL_BRIDGER:-'true'}
INSTALL_DAWN=${INSTALL_DAWN:-'false'}
INSTALL_USTEER=${INSTALL_USTEER:-'false'}
DOH_PACKAGE=${DOH_PACKAGE:-'stubby'} # can be also: luci-app-unbound or dnscrypt-proxy2 or adguardhome or stubby
CRYPTO_LIB=${CRYPTO_LIB:-'openssl'}  # wolfssl or openssl or mbedtls
# ADDITIONAL_PACKAGES=${ADDITIONAL_PACKAGES:-'kmod-mt7921e kmod-mt7921-common kmod-mt7921-firmware kmod-mt7925-common kmod-mt7925e luci-app-nft-qos'}
ADDITIONAL_PACKAGES=${ADDITIONAL_PACKAGES:-'bmon tcpdump iperf3 ethtool-full vim'}
INSTALL_LANG_PACKAGES=${INSTALL_LANG_PACKAGES:-'true'}
INSTALL_MINIMUM_PACKAGES=${INSTALL_MINIMUM_PACKAGES:-'false'}
SQM_TOOL=${SQM_TOOL:-'qosify'}                      # qosify or luci-app-sqm
SPEEDTEST_TOOLS=${SPEEDTEST_TOOLS:='librespeed-go'} # librespeed-go

if [ -z "$ROUTER_IP" ]; then
    echo "Please provide router ip like: 192.168.1.1"
    exit 1
fi

COMMAND="apk update"

if [[ "$FULL_WPAD" =~ True|true ]]; then
    FS_FULL_WPAD_PACKAGES="-wpad-basic-mbedtls"
fi

if [[ "$CRYPTO_LIB" =~ ^(Wolfssl|wolfssl)$ ]]; then
    # MAKE SURE IT IS ARMv8 or Intel AESNI, otherwise use: CONFIG_PACKAGE_libwolfssl=y
    echo -e "\n\n If this is ARMv8, you can replace libwolfssl with libwolfsslcpu-crypto \n\n"
    FS_FULL_WPAD_PACKAGES="$FS_FULL_WPAD_PACKAGES wpad-wolfssl luci-ssl"
elif [[ "$CRYPTO_LIB" =~ ^(Openssl|openssl)$ ]]; then
    FS_FULL_WPAD_PACKAGES="$FS_FULL_WPAD_PACKAGES wpad-openssl luci-openssl"
elif [[ "$CRYPTO_LIB" =~ ^(Mbedtls|mbedtls)$ ]]; then
    FS_FULL_WPAD_PACKAGES="$FS_FULL_WPAD_PACKAGES wpad-mbedtls luci-ssl"
    COMMAND="$COMMAND; apk del wpad-basic-mbedtls; apk add wpad-mbedtls"
fi

# basic packages
PACKAGES="collectd collectd-mod-sensors \
collectd-mod-dns collectd-mod-wireless \
luci-app-statistics luci htop curl owut \
irqbalance luci-app-irqbalance"

# additional
# fping kmod-crypto-user kmod-cryptodev

if [[ "$INSTALL_MINIMUM_PACKAGES" =~ True|true ]]; then
    if [[ "$CRYPTO_LIB" =~ ^(Wolfssl|wolfssl|Openssl|openssl)$ ]]; then
        echo -e "By choosing INSTALL_MINIMUM_PACKAGES, consider to use:\n\n export CRYPTO_LIB=mbedtls\n\n"
    fi
    if [[ "$DOH_PACKAGE" =~ dnscrypt-proxy2|adguardhome ]]; then
        echo -e "It is not good to choose $DOH_PACKAGE on low space device!"
        exit 1
    fi

fi

if [[ "$INSTALL_DAWN" =~ True|true ]]; then
    PACKAGES="$PACKAGES dawn luci-app-dawn"
fi

if [[ "$INSTALL_USTEER" =~ True|true ]]; then
    PACKAGES="$PACKAGES usteer luci-app-usteer luci-i18n-usteer-pl"
fi

# additional packages
if [[ "$DEVICE" =~ Main|main ]]; then
    PACKAGES="$PACKAGES ddns-scripts luci-app-ddns"
    PACKAGES="$PACKAGES luci-proto-wireguard kmod-wireguard wireguard-tools qrencode"
    PACKAGES="$PACKAGES tc-full pciutils"
    if [ -n "$SQM_TOOL" ]; then
        PACKAGES="$PACKAGES $SQM_TOOL"
    fi

    if [ -n "$DOH_PACKAGE" ]; then
        PACKAGES="$PACKAGES $DOH_PACKAGE"
    fi

    if [ -n "$SPEEDTEST_TOOLS" ]; then
        PACKAGES="$PACKAGES $SPEEDTEST_TOOLS"
    fi
fi

# NOTE: to enable WED for L2, you need to install bridger,
# otherwise WED would be just working for L3
# Also it is important to enable HW offload and
# do not disable firewall on dumb ap's.
if [[ "$INSTALL_BRIDGER" =~ True|true ]]; then
    PACKAGES="$PACKAGES bridger"
fi

if [[ "$INSTALL_LANG_PACKAGES" =~ True|true ]]; then
    PACKAGES="$PACKAGES luci-i18n-firewall-pl luci-i18n-irqbalance-pl luci-i18n-statistics-pl luci-i18n-base-pl"
fi

COMMAND="$COMMAND; apk add $PACKAGES $ADDITIONAL_PACKAGES; /etc/init.d/uhttpd start ; /etc/init.d/uhttpd enable;"

read -n 1 -r -p "Should I execute command: $COMMAND on root@$ROUTER_IP? " yn
case $yn in
[Yy]*) ssh "root@$ROUTER_IP" "$COMMAND $PACKAGES" ;;
[Nn]*)
    echo -e "\n\nFor firmware-selector.org: \n\n$PACKAGES $FS_FULL_WPAD_PACKAGES $ADDITIONAL_PACKAGES"
    exit 0
    ;;
*) echo "Please answer yes or no. If no, will show you packages for firmware-selector ;)" ;;
esac

echo -e "\n\nPackage installation completed!\n\n"
read -n 1 -r -p "Should I reboot device $ROUTER_IP? " yn
case $yn in
[Yy]*) ssh "root@$ROUTER_IP" reboot ;;
[Nn]*) exit ;;
*) echo "Please answer yes or no." ;;
esac

# For https://firmware-selector.openwrt.org/
# Add packages. NOTE: To install wpad-wolfssl, just replace the package name with wpad-basic-wolfssl
### basic
#       apk update;
#       apk add collectd collectd-mod-sensors collectd-mod-dns collectd-mod-wireless luci-app-statistics luci luci-i18n-base-pl vim htop curl iperf3 luci-app-attendedsysupgrade auc bmon irqbalance luci-app-irqbalance rsync
#
### additional
#       apk add ethtool-full pciutils tcpdump

### wireguard
#       luci-proto-wireguard kmod-wireguard wireguard-tools qrencode

### DNS over HTTPS
#       unbound-daemon luci-app-unbound

### DDNS
#       ddns-scripts luci-app-ddns

### Bufferbloat - install SQM - https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm
#       luci-app-sqm luci-i18n-sqm-pl sqm-scripts-extra
#       # OR
#       qosify - https://forum.openwrt.org/t/qosify-new-package-for-dscp-marking-cake/111789/1122

### Better roaming
#       usteer luci-app-usteer
# OR
#       dawn luci-app-dawn
#
### Limit bandwidth
#       luci-app-nft-qos

### to use mbedtls, replace:
# libustream-wolfssl and wpad-basic-wolfssl *WITH* libustream-mbedtls and wpad-basic-mbedtls.

# to enable 802.11k/v replace:
# wpad-basic-mbedtls with wpad-mbedtls

# To replace mbedtls with openssl via firmware-selector, just add:
# -wpad-basic-mbedtls -libustream-mbedtls -libmbedtls libustream-openssl wpad-openssl -apk-mbedtls apk-openssl
#
# To replace mbedtls with wolfssl via firmware-selector, just add:
# -wpad-basic-mbedtls -libustream-mbedtls -libmbedtls libustream-wolfssl wpad-wolfssl -apk-mbedtls apk-wolfssl
#
