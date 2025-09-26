# OpenWRT wireless configuration with enabled Fast Roaming (802.11r/k/v/w)

tl;dr

Whats working:

- stable configuration of wireless configuration, roaming works well
- bandwidth 95% on 5GHz

Known issues:

- slow speed on Samsung Smart TV on 5GHZ network (MyNetwork SSID)

Changes comparing to simple:

- enable 802.11v
- enabled 802.11k
- set 802.11w as optional
- set dtim_period to '3' [base on Unifi settings](https://evanmccann.net/blog/2021/11/unifi-advanced-wi-fi-settings)

Scheme:

```sh
                                    +-----------------------------------------+
+-----------------------------------|-----+                                   |
|                                   |     |                                   |
|                                   |     |                                   |
|              MAIN                 |     |            AP1                    |
|      +----------------------+     |     |      +--------------------+       |
|      |                      |     |     |      |                    |       |
|      | MyNetwork_2G         |     |     |      |MyNetwork_2G        |       |
|      |   WPA2, CH4, 40MHz,  |     |     |      | WPA2, CH8, 40MHz,  |       |
|      |   NASID main-2,      |     |     |      | NASID: ap1-2,      |       |
|      |   DOMAINID: abab     |     |     |      | DOMAINID: abab     |       |
|      |                      |     |     |      |                    |       |
|      |                      |<----|-----|----->|                    |       |
|      | MyNetwork            |     |     |      |MyNetwork           |       |
|      |   WPA2, CH124, 160MHz|     |     |      | WPA2, CH104, 80MHz |       |
|      |   NASID: main-5,     |     |     |      | NASID: ap-5,       |       |
|      |   DOMAINID: abab     |     |     |      | DOMAINID: abab     |       |
|      |                      |     |     |      |                    |       |
|      +----------------------+     |     |      +--------------------+       |
|                                   |     |                                   |
+-----------------------------------|-----+                                   |
                                    +-----------------------------------------+
```

###################################
#### MAIN /etc/config/wireless ####
###################################

```sh
config wifi-device 'radio0'
	option type 'mac80211'
	option path 'platform/18000000.wmac'
	option channel '4'
	option band '2g'
	option htmode 'HT40'
	option txpower '18'
	option country 'PL'
	option cell_density '0'

config wifi-iface 'default_radio0'
	option device 'radio0'
	option network 'lan'
	option mode 'ap'
	option ssid 'MyNetwork_2G'
	option encryption 'psk2'
	option key 'mypassword1234'

config wifi-device 'radio1'
	option type 'mac80211'
	option path '1a143000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0'
	option channel '104'
	option band '5g'
	option htmode 'HE160'
	option country 'PL'
	option txpower '23'
	option cell_density '0'
	option log_level '1'

config wifi-iface 'default_radio1'
	option device 'radio1'
	option network 'lan'
	option mode 'ap'
	option ssid 'MyNetwork'
	option encryption 'psk2'
	option key 'mypassword1234'
	option ieee80211r '1'
	option nasid 'main-5'
	option mobility_domain 'abab'
	option ft_over_ds '1'
	option ft_psk_generate_local '1'
	option ieee80211k '1'
	option ieee80211v '1'
	option bss_transition '1'
	option wnm_sleep_mode '1'
	option ieee80211w '1'

config wifi-iface 'wifinet3'
	option device 'radio1'
	option mode 'ap'
	option ssid 'MyNetwork_iot'
	option encryption 'psk2'
	option key 'mypassword1234'
	option network 'lan'
	option bss_transition '1'
	option disassoc_low_ack '0'
```

##################################
#### AP1 /etc/config/wireless ####
##################################

```sh
config wifi-device 'radio0'
	option type 'mac80211'
	option path '1e140000.pcie/pci0000:00/0000:00:01.0/0000:02:00.0'
	option channel '8'
	option band '2g'
	option htmode 'HT40'
	option txpower '18'
	option country 'PL'
	option cell_density '0'

config wifi-iface 'default_radio0'
	option device 'radio0'
	option network 'lan'
	option mode 'ap'
	option ssid 'MyNetwork_2G'
	option encryption 'psk2'
	option key 'mypassword1234'

config wifi-device 'radio1'
	option type 'mac80211'
	option path '1e140000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0'
	option channel '124'
	option band '5g'
	option htmode 'VHT80'
	option country 'PL'
	option txpower '18'
	option cell_density '0'
	option log_level '1'

config wifi-iface 'default_radio1'
	option device 'radio1'
	option network 'lan'
	option mode 'ap'
	option ssid 'MyNetwork'
	option encryption 'psk2'
	option key 'mypassword1234'
	option ieee80211r '1'
	option nasid '4a-5'
	option mobility_domain 'abab'
	option ft_over_ds '1'
	option ft_psk_generate_local '1'
	option ieee80211k '1'
	option ieee80211v '1'
	option bss_transition '1'
	option wnm_sleep_mode '1'
	option ieee80211w '1'

config wifi-iface 'wifinet3'
	option device 'radio1'
	option mode 'ap'
	option ssid 'MyNetwork_iot'
	option encryption 'psk2'
	option key 'mypassword1234'
	option network 'lan'
	option bss_transition '1'
	option disabled '1'
```
