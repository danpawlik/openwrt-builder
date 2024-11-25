#!/bin/bash

git clone https://github.com/DNSCrypt/dnscrypt-proxy
cd dnscrypt-proxy/utils/generate-domains-blocklist

cat << EOF > domains-blocklist.conf
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/notrack-blocklist.txt
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/notrack-malware.txt
https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_3_Spyware/filter.txt
EOF

echo 'googleadservices.com' >> domains-allowlist.txt
echo "server:" > unbound_ext.conf

for domain in $(./generate-domains-blocklist.py | sed '/^$/d'| sed '/#/d'); do
    echo -e "\tlocal-zone: \"$domain.\" refuse";
done >> unbound_ext.conf

cd -

# scp -O dnscrypt-proxy/utils/generate-domains-blocklist/unbound_ext.conf root@<your ip address>:/etc/unbound/unbound_ext.conf
