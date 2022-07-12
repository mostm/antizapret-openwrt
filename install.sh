#!/bin/ash

# Before install
# Connect to VPN and declare an interface.
# This script assumes you have installed WireGuard, and have default wg0 interface.

# Dependencies:
# If not already, manually reinstall dnsmasq from minimal to full version
# opkg remove dnsmasq
# opkg install dnsmasq-full
# If your ISP uses plain DHCP configuration:
# You might need to fetch package manually before removing dnsmasq

opkg install curl iconv coreutils-stat gawk sipcalc idn python3 python3-pip grep
pip install dnspython

# Apply all of configurations from https://habr.com/ru/post/440030/
# Do not install /etc/init.d/hirkn or execute it

# Finishing
mkdir -p /etc/dnsmasq.d/

./doall.sh