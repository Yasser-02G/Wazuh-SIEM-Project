#!/bin/sh
# Wazuh Active Response - SSH Brute Force IP Block
# Placeholder script — replace with your actual active-response logic
# or reference the built-in Wazuh "firewall-drop" script instead.
#
# Wazuh already ships a default firewall-drop.sh under:
#   /var/ossec/active-response/bin/firewall-drop.sh
# This custom script is only needed if you extend the default behavior.

LOCAL=$(dirname $0)
cd $LOCAL
cd ../

read INPUT_JSON
SRCIP=$(echo $INPUT_JSON | grep -oP '"srcip":"\K[^"]+')

if [ ! -z "$SRCIP" ]; then
    iptables -I INPUT -s $SRCIP -j DROP
    echo "$(date) Blocked IP: $SRCIP" >> /var/ossec/logs/active-responses.log
fi
