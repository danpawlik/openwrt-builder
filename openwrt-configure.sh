#!/bin/bash

# Example usage:
# ./openwrt-configure.sh 192.168.88.1 main
# ./openwrt-configure.sh 192.168.88.2

ROUTER_IP="${ROUTER_IP=$1}"
# DEVICE can be main or <nothing>
DEVICE="${DEVICE:-$2}"
FULL_WPAD="${FULL_WPAD:-'yes'}"
INSTALL_BRIDGER=${INSTALL_BRIDGER:-'true'}
CRYPTO_LIB=${CRYPTO_LIB:-'openssl'}

if [ -z "$ROUTER_IP" ]; then
    echo "Please provide router ip like: 192.168.1.1"
    exit 1
fi

COMMAND="opkg update"
#if [[ "$FULL_WPAD" =~ yes|Yes ]]; then
#  COMMAND="$COMMAND; opkg remove wpad-basic-mbedtls; opkg install wpad-$CRYPTO_LIB"
#fi

# basic packages
COMMAND="$COMMAND; opkg install collectd collectd-mod-sensors collectd-mod-irq \
collectd-mod-dns collectd-mod-wireless \
luci-app-statistics luci vim htop \
curl iperf3 luci-app-attendedsysupgrade \
auc bmon irqbalance rsync"

# additional packages
if [[ "$DEVICE" =~ Main|main ]]; then
    COMMAND="$COMMAND collectd-mod-dhcpleases collectd-mod-thermal"
    COMMAND="$COMMAND luci-app-wireguard luci-proto-wireguard kmod-wireguard wireguard-tools qrencode"
    COMMAND="$COMMAND https-dns-proxy luci-app-https-dns-proxy luci-i18n-https-dns-proxy-pl libcurl4 libnghttp3 libngtcp2"
    COMMAND="$COMMAND luci-app-sqm collectd-mod-sqm"
    COMMAND="$COMMAND ddns-scripts luci-app-ddns bind-host"
fi

if ! [[ "$DEVICE" =~ Main|main ]] && [[ "$INSTALL_BRIDGER" =~ True|true ]]; then
    COMMAND="$COMMAND bridger"
fi

COMMAND="$COMMAND; /etc/init.d/uhttpd start ; /etc/init.d/uhttpd enable;"

read -n 1 -r -p "Should I execute command: $COMMAND on root@$ROUTER_IP? " yn
case $yn in
    [Yy]* ) ssh "root@$ROUTER_IP" "$COMMAND";;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
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
#       opkg install collectd collectd-mod-sensors collectd-mod-irq collectd-mod-dns collectd-mod-wireless luci-app-statistics luci luci-i18n-base-pl vim htop curl iperf3 luci-app-attendedsysupgrade auc bmon irqbalance rsync

### wireguard
#       luci-app-wireguard luci-proto-wireguard kmod-wireguard wireguard-tools qrencode

### DNS over HTTPS
#       https-dns-proxy luci-app-https-dns-proxy luci-i18n-https-dns-proxy-pl libcurl4 libnghttp3 libngtcp2

### DDNS
#       ddns-scripts luci-app-ddns bind-host

### Bufferbloat - install SQM - https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm
#       luci-app-sqm luci-i18n-sqm-pl collectd-mod-sqm sqm-scripts-extra

### Others
#       collectd-mod-dhcpleases collectd-mod-thermal

### to use mbedtls, replace:
# libustream-wolfssl and wpad-basic-wolfssl *WITH* libustream-mbedtls and wpad-basic-mbedtls.

# to enable 802.11k/v replace:
# wpad-basic-mbedtls with wpad-mbedtls
