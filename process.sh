#!/bin/bash
set -e

rm -rf /etc/dnsmasq.d/antizapret-openwrt.conf
ipset flush vpn_ipsum
mkdir -p /etc/dnsmasq.d/
cp result/dnsmasq-ipset.conf /etc/dnsmasq.d/antizapret-openwrt.conf
# i have no idea why or how, but this command makes it all work
iptables -I PREROUTING -t mangle -m set --match-set vpn_ipsum dst -j MARK --set-mark 1
/etc/init.d/dnsmasq restart
/etc/init.d/firewall restart
iptables -I PREROUTING -t mangle -m set --match-set vpn_ipsum dst -j MARK --set-mark 1
echo "\"no lease, failing\" error is normal."

exit 0
