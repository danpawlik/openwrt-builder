#!/bin/bash

# Example usage:
# ./openwrt-configure.sh 192.168.88.1 main
# ./openwrt-configure.sh 192.168.88.2

ROUTER_IP="${ROUTER_IP=$1}"
# DEVICE can be main or <nothing>
DEVICE="${DEVICE:-$2}"
FULL_WPAD="${FULL_WPAD:-'true'}"
INSTALL_BRIDGER=${INSTALL_BRIDGER:-'false'}
INSTALL_DAWN=${INSTALL_DAWN:-'false'}
INSTALL_USTEER=${INSTALL_USTEER:-'true'}
INSTALL_DNSCRYPT_PROXY2=${INSTALL_DNSCRYPT_PROXY2:-'false'}
INSTALL_UNBOUND=${INSTALL_UNBOUND:-'true'}
CRYPTO_LIB=${CRYPTO_LIB:-'openssl'} # wolfssl or openssl; if empty - mbedtls
# ADDITIONAL_DRIVERS=${ADDITIONAL_DRIVERS:-'kmod-mt7921e kmod-mt7921-common kmod-mt7921-firmware kmod-mt7925-common kmod-mt7925e'}
ADDITIONAL_DRIVERS=${ADDITIONAL_DRIVERS:-''}
INSTALL_LANG_PACKAGES=${INSTALL_LANG_PACKAGES:-'true'}
INSTALL_MINIMUM_PACKAGES=${INSTALL_MINIMUM_PACKAGES:-'false'}

if [ -z "$ROUTER_IP" ]; then
    echo "Please provide router ip like: 192.168.1.1"
    exit 1
fi

COMMAND="opkg update"

if [[ "$FULL_WPAD" =~ True|true ]]; then
    FS_FULL_WPAD_PACKAGES="-wpad-basic-mbedtls"
fi

if [ -z "$CRYPTO_LIB" ]; then
    FS_FULL_WPAD_PACKAGES="$FS_FULL_WPAD_PACKAGES wpad-mbedtls"
    COMMAND="$COMMAND; opkg remove wpad-basic-mbedtls; opkg install wpad-mbedtls"
fi

if [ -n "$CRYPTO_LIB" ]; then
  COMMAND="$COMMAND; opkg remove wpad-basic-mbedtls; opkg install wpad-$CRYPTO_LIB"

  if [[ "$CRYPTO_LIB" =~ ^(Wolfssl|wolfssl)$ ]]; then
    FS_FULL_WPAD_PACKAGES="$FS_FULL_WPAD_PACKAGES -libustream-mbedtls -libmbedtls libustream-wolfssl wpad-wolfssl"
  elif [[ "$CRYPTO_LIB" =~ ^(Openssl|openssl)$ ]]; then
    FS_FULL_WPAD_PACKAGES="$FS_FULL_WPAD_PACKAGES -libustream-mbedtls -libmbedtls libustream-openssl wpad-openssl libopenssl-devcrypto libopenssl-afalg_sync"
  fi
fi

# basic packages
PACKAGES="collectd collectd-mod-sensors \
collectd-mod-dns collectd-mod-wireless \
luci-app-statistics luci vim htop curl iperf3 owut \
irqbalance luci-app-irqbalance"

if [[ "$INSTALL_MINIMUM_PACKAGES" =~ False|false ]]; then
    PACKAGES="$PACKAGES bmon rsync bind-dig ethtool-full pciutils tcpdump"
else
    if [[ "$CRYPTO_LIB" =~ ^(Wolfssl|wolfssl|Openssl|openssl)$ ]]; then
        echo -e "By choosing INSTALL_MINIMUM_PACKAGES, consider to use:\n\n export CRYPTO_LIB=mbedtls\n\n"
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
    PACKAGES="$PACKAGES luci-proto-wireguard kmod-wireguard wireguard-tools qrencode"
    PACKAGES="$PACKAGES luci-app-sqm"
    PACKAGES="$PACKAGES ddns-scripts luci-app-ddns bind-host"
    if [[ "$INSTALL_DNSCRYPT_PROXY2" =~ True|true ]]; then
        PACKAGES="$PACKAGES dnscrypt-proxy2"
    fi
    if [[ "$INSTALL_UNBOUND" =~ True|true ]]; then
        PACKAGES="$PACKAGES unbound-daemon luci-app-unbound"
    fi
fi

if ! [[ "$DEVICE" =~ Main|main ]] && [[ "$INSTALL_BRIDGER" =~ True|true ]]; then
    PACKAGES="$PACKAGES bridger"
fi

if [[ "$INSTALL_LANG_PACKAGES" =~ True|true ]]; then
    PACKAGES="$PACKAGES luci-i18n-firewall-pl luci-i18n-irqbalance-pl luci-i18n-opkg-pl luci-i18n-statistics-pl luci-i18n-base-pl"
fi

COMMAND="$COMMAND; opkg install $PACKAGES $ADDITIONAL_DRIVERS; /etc/init.d/uhttpd start ; /etc/init.d/uhttpd enable;"

read -n 1 -r -p "Should I execute command: $COMMAND on root@$ROUTER_IP? " yn
case $yn in
    [Yy]* ) ssh "root@$ROUTER_IP" "$COMMAND $PACKAGES";;
    [Nn]* ) echo -e "\n\nFor firmware-selector.org: \n\n$PACKAGES $FS_FULL_WPAD_PACKAGES $ADDITIONAL_DRIVERS" ; exit 0;;
    * ) echo "Please answer yes or no. If no, will show you packages for firmware-selector ;)";;
esac

echo -e "\n\nPackage installation completed!\n\n"
read -n 1 -r -p "Should I reboot device $ROUTER_IP? " yn
case $yn in
    [Yy]* ) ssh "root@$ROUTER_IP" reboot;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
esac

# For https://firmware-selector.openwrt.org/
# Add packages. NOTE: To install wpad-wolfssl, just replace the package name with wpad-basic-wolfssl
### basic
#       opkg update;
#       opkg install collectd collectd-mod-sensors collectd-mod-dns collectd-mod-wireless luci-app-statistics luci luci-i18n-base-pl vim htop curl iperf3 luci-app-attendedsysupgrade auc bmon irqbalance luci-app-irqbalance rsync
#
### additional
#       opkg install bind-dig ethtool-full pciutils tcpdump

### wireguard
#       luci-proto-wireguard kmod-wireguard wireguard-tools qrencode

### DNS over HTTPS
        unbound-daemon luci-app-unbound

### DDNS
#       ddns-scripts luci-app-ddns bind-host

### Bufferbloat - install SQM - https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm
#       luci-app-sqm luci-i18n-sqm-pl sqm-scripts-extra

### Better roaming
#       usteer luci-app-usteer
# OR
#       dawn luci-app-dawn

### to use mbedtls, replace:
# libustream-wolfssl and wpad-basic-wolfssl *WITH* libustream-mbedtls and wpad-basic-mbedtls.

# to enable 802.11k/v replace:
# wpad-basic-mbedtls with wpad-mbedtls

# To replace mbedtls with openssl via firmware-selector, just add:
# -wpad-basic-mbedtls -libustream-mbedtls -libmbedtls libustream-openssl wpad-openssl
#
# To replace mbedtls with wolfssl via firmware-selector, just add:
# -wpad-basic-mbedtls -libustream-mbedtls -libmbedtls libustream-wolfssl wpad-wolfssl
