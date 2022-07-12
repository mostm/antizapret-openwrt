#!/bin/bash

echo "Parsing antizapret lists. This might take a while due to CPU limitations."

set -e

source config/config.sh

HERE="$(dirname "$(readlink -f "${0}")")"
cd "$HERE"

# Extract domains from list
echo "Stage: Extracting domains from list"
gawk -F ';' '{print $2}' temp/list.csv | sort -u | gawk '/^$/ {next} /\\/ {next} /^[а-яА-Яa-zA-Z0-9\-_\.\*]*+$/ {gsub(/\*\./, ""); gsub(/\.$/, ""); print}' | CHARSET=UTF-8 idn > result/hostlist_original.txt

# Generate zones from domains
# FIXME: nxdomain list parsing is disabled due to its instability on z-i
###cat exclude.txt temp/nxdomain.txt > temp/exclude.txt
echo "Stage: Generate zones from domains"

echo "Created temp include/exclude files"
sort -u config/exclude-hosts-{dist,custom}.txt > temp/exclude-hosts.txt
sort -u config/exclude-ips-{dist,custom}.txt > temp/exclude-ips.txt
sort -u config/include-hosts-{dist,custom}.txt > temp/include-hosts.txt
sort -u config/include-ips-{dist,custom}.txt > temp/include-ips.txt
sort -u temp/include-hosts.txt result/hostlist_original.txt > temp/hostlist_original_with_include.txt

echo "Adding distributed excluded hosts to preferences file"
gawk -F ';' '{split($1, a, /\|/); for (i in a) {print a[i]";"$2}}' temp/list.csv | \
 grep -f config/exclude-hosts-by-ips-dist.txt | gawk -F ';' '{print $2}' >> temp/exclude-hosts.txt

echo "Removing excluded hosts from total hostlist"
gawk -f scripts/getzones.awk temp/hostlist_original_with_include.txt | grep -v -F -x -f temp/exclude-hosts.txt | sort -u > result/hostlist_zones.txt


if [[ "$RESOLVE_NXDOMAIN" == "yes" ]];
then
    echo "Resolving NXDomain zones"
    scripts/resolve-dns-nxdomain.py result/hostlist_zones.txt >> temp/exclude-hosts.txt
    echo "NXDomain zones exclusion "
    gawk -f scripts/getzones.awk temp/hostlist_original_with_include.txt | grep -v -F -x -f temp/exclude-hosts.txt | sort -u > result/hostlist_zones.txt
fi

# Generate a list of IP addresses
echo "Stage: Generate a list of IP addresses"

# echo "generating iplist_special_range.txt"
# gawk -F';' '$1 ~ /\// {print $1}' temp/list.csv | grep -P '([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}' -o | sort -Vu > result/iplist_special_range.txt
# 
# echo "generating iplist_all.txt"
# gawk -F ';' '($1 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}/) {gsub(/\|/, RS, $1); print $1}' temp/list.csv | \
#     gawk '/^([0-9]{1,3}\.){3}[0-9]{1,3}$/' | sort -u > result/iplist_all.txt
# 
# echo "generating iplist_blockedbyip.txt"
# gawk -F ';' '($1 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}/) && (($2 == "" && $3 == "") || ($1 == $2)) {gsub(/\|/, RS); print $1}' temp/list.csv | \
#     gawk '/^([0-9]{1,3}\.){3}[0-9]{1,3}$/' | sort -u > result/iplist_blockedbyip.txt
# 
# echo "generating iplist_blockedbyip_noid2971.txt"
# grep -F -v '33-4/2018' temp/list.csv | grep -F -v '33а-5536/2019' | \
#     gawk -F ';' '($1 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}/) && (($2 == "" && $3 == "") || ($1 == $2)) {gsub(/\|/, RS); print $1}' | \
#     gawk '/^([0-9]{1,3}\.){3}[0-9]{1,3}$/' | sort -u > result/iplist_blockedbyip_noid2971.txt

echo "generating blocked-ranges.txt"
gawk -F ';' '$1 ~ /\// {print $1}' temp/list.csv | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}' | sort -u > result/blocked-ranges.txt

# Generate dnsmasq aliases
echo "Generating dnsmasq-ipset configuration"
echo -n > result/dnsmasq-ipset.conf
while read -r line
do
    echo "server=/$line/127.0.0.1" >> result/dnsmasq-ipset.conf
    echo "ipset=/$line/vpn_ipsum" >> result/dnsmasq-ipset.conf
done < result/hostlist_zones.txt


# Print results
echo "Blocked domains: $(wc -l result/hostlist_zones.txt)" >&2
echo "iplist_all: $(wc -l result/iplist_all.txt)" >&2
echo "iplist_special_range: $(wc -l result/iplist_special_range.txt)" >&2
echo "iplist_blockedbyip: $(wc -l result/iplist_blockedbyip.txt)" >&2
echo "iplist_blockedbyip_noid2971: $(wc -l result/iplist_blockedbyip_noid2971.txt)" >&2

exit 0
