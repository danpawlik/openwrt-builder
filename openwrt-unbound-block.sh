#!/bin/sh

# Set custom domain filtering in unbound.
# It is temporary workaround until nextdns request quota is not reset.

# NextDNS rules:
#   NoTrack Tracker Blocklist
#   EasyPrivacy
#   AdGuard Tracking Protection filter

TMP_FILE=/tmp/adblock

# Example whitelist: googleadservices.com|test.com|<other>|<other>
ALLOW_DOMAINS='googleadservices.com'

if [ -f $TMP_FILE ]; then rm $TMP_FILE; fi
touch $TMP_FILE

# NoTrack Tracker Blocklist
curl -SL https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/notrack-blocklist.txt | sed 's/\#.*//g' | grep -v '^\s*$' >> "$TMP_FILE"
curl -SL https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/notrack-malware.txt | sed 's/\#.*//g' | grep -v '^\s*$' >> "$TMP_FILE"

# EasyPrivacy
curl -SL https://easylist.to/easylist/easyprivacy.txt |  grep -E '^||' | grep -vE '@|---|!' | sed 's/||//g' >> "$TMP_FILE"

# https://github.com/FiltersHeroes/KADhosts/tree/master
curl -SL https://raw.githubusercontent.com/FiltersHeroes/KADhosts/refs/heads/master/KADhosts.txt | grep '0.0.0.0' | awk '{print $2}' >> "$TMP_FILE"

# Adguard Tracking Protection filter
# curl -SL https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_3_Spyware/filter.txt | grep -E '^\|\|' | sed 's/\^.*//g' | sed 's/||//g' | cut -f1 -d'/' | sort  | uniq >>  "$TMP_FILE"

echo "server:" > /etc/unbound/unbound_ext.conf
# consider: grep -E '^[a-zA-Z0-9.]'
sort -u "$TMP_FILE" | grep -E '^[a-zA-Z0-9]' | grep -vE '/|!|\^|\(|\)|#|\.$' | grep -vE "$ALLOW_DOMAINS" | while read -r domain; do
    echo -e "\tlocal-zone: \"$domain.\" refuse" >> /etc/unbound/unbound_ext.conf
done

/etc/init.d/unbound restart
