# OpenWRT wireless configuration with enabled Fast Roaming (802.11r)

tl;dr

Whats working:

- stable configuration of wireless configuration,

Known issues:

- bandwidth 80% on 5GHz
- slow speed on Samsung Smart TV on 5GHZ network (MyNetwork SSID)

Scheme:
```
                                  +---------------------------------------+
+---------------------------------|-----+                                 |
|                                 |     |                                 |
|                                 |     |                                 |
|              MAIN               |     |            AP1                  |
|      +--------------------+     |     |      +------------------+       |
|      |                    |     |     |      |                  |       |
|      | MyNetwork_2G       |     |     |      |MyNetwork_2G      |       |
|      |   WPA2, CH2, 40MHz,|     |     |      | WPA2, CH8, 40MHz,|       |
|      |   NASID main-2,    |     |     |      | NASID: ap1-2,    |       |
|      |   DOMAINID: abab   |     |     |      | DOMAINID: abab   |       |
|      |                    |     |     |      |                  |       |
|      |                    |<----|-----|----->|                  |       |
|      | MyNetwork          |     |     |      |MyNetwork         |       |
|      |   WPA2, CH40, 80MHz|     |     |      | WPA2, CH48, 80MHz|       |
|      |   NASID: main-5,   |     |     |      | NASID: ap-5,     |       |
|      |   DOMAINID: abab   |     |     |      | DOMAINID: abab   |       |
|      |                    |     |     |      |                  |       |
|      +--------------------+     |     |      +------------------+       |
|                                 |     |                                 |
+---------------------------------|-----+                                 |
                                  +---------------------------------------+

```

###################################
#### MAIN /etc/config/wireless ####
###################################

```sh
config wifi-device 'radio0'
	option type 'mac80211'
	option path 'platform/18000000.wmac'
	option band '2g'
	option htmode 'HT40'
	option channel '2'
	option country 'PL'
	option cell_density '3'

config wifi-iface 'default_radio0'
	option device 'radio0'
	option network 'lan'
	option mode 'ap'
	option ssid 'MyNetwork_2G'
	option multicast_to_unicast '1'
	option encryption 'psk2'
	option ieee80211r '1'
	option nasid 'main-2'
	option mobility_domain 'abab'
	option ft_over_ds '1'
	option ft_psk_generate_local '1'
	option key 'mypassword1234'
	option ieee80211w '2'

config wifi-device 'radio1'
	option type 'mac80211'
	option path '1a143000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0'
	option band '5g'
	option htmode 'HE80'
	option channel '40'
	option country 'PL'
	option cell_density '3'

config wifi-iface 'default_radio1'
	option device 'radio1'
	option network 'lan'
	option mode 'ap'
	option ssid 'MyNetwork'
	option multicast_to_unicast '1'
	option encryption 'psk2'
	option ieee80211r '1'
	option nasid 'main-5'
	option mobility_domain 'abab'
	option ft_over_ds '1'
	option ft_psk_generate_local '1'
	option key 'mypassword1234'
	option ieee80211w '2'

config wifi-iface 'wifinet2'
	option device 'radio0'
	option mode 'ap'
	option ssid 'MyNetwork_tv'
	option encryption 'psk2+tkip'
	option multicast_to_unicast '1'
	option isolate '1'
	option key 'somepass1234'
	option network 'lan'
	option disabled '1'
```

##################################
#### AP1 /etc/config/wireless ####
##################################

```sh
config wifi-device 'radio0'
	option type 'mac80211'
	option path '1e140000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0'
	option band '2g'
	option htmode 'HT40'
	option country 'PL'
	option channel '8'
	option cell_density '3'

config wifi-device 'radio1'
	option type 'mac80211'
	option path '1e140000.pcie/pci0000:00/0000:00:01.0/0000:02:00.0'
	option band '5g'
	option country 'PL'
	option cell_density '3'
	option htmode 'HE80'
	option txpower '17'
	option channel '48'

config wifi-iface 'wifinet0'
	option device 'radio1'
	option mode 'ap'
	option ssid 'MyNetwork'
	option encryption 'psk2'
	option key 'mypassword1234'
	option ieee80211r '1'
	option mobility_domain 'abab'
	option ft_over_ds '1'
	option ft_psk_generate_local '1'
	option network 'lan'
	option nasid 'ap1-5'
	option ieee80211w '2'

config wifi-iface 'wifinet1'
	option device 'radio0'
	option mode 'ap'
	option ssid 'MyNetwork_2G'
	option encryption 'psk2'
	option key 'mypassword1234'
	option ieee80211r '1'
	option mobility_domain 'abab'
	option ft_over_ds '1'
	option ft_psk_generate_local '1'
	option network 'lan'
	option nasid 'ap1-2'
	option ieee80211w '2'

config wifi-iface 'wifinet2'
	option device 'radio0'
	option mode 'ap'
	option ssid 'MyNetwork_tv'
	option encryption 'psk2+tkip'
	option isolate '1'
	option key 'somepass1234'
	option network 'lan'
```
