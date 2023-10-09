#!/usr/bin/env bash

##
# NAME: Linux Update Status (APT and DNF/YUM)
# Original script: https://discord.com/channels/736478043522072608/744281869499105290/1150100715688169592
#
# DESCRIPTION:
#   Returns if package updates are available for installation
#
# EXIT CODES:
# - 0: script has determined no updates are required
# - 1: Urgent updates are available
# - 2: Security updates are available
# - 3: Normal updates are available
# - 20: Misc warnings
##

# Check if the system uses dnf/yum or apt
if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
    package_manager="dnf/yum"
elif command -v apt &>/dev/null; then
    package_manager="apt"
else
    printf "UNSUPPORTED PACKAGE MANAGER\n"
    exit 20
fi

pkg_count=0
sec_count=0
important_sec_count=0

if [ "$package_manager" = "dnf/yum" ]; then
    # Check if DNF Make Cache timer is enabled
    if ! systemctl is-enabled dnf-makecache.timer &>/dev/null; then
        printf "DNF MAKECACHE NOT ENABLED\n"
        exit 20
    fi

    pkg_count=$(yum --cacheonly --quiet list --updates 2>/dev/null | grep -v "Available Upgrades" | wc -l)
    sec_count=$(yum --cacheonly --quiet list --updates --security 2>/dev/null | grep -v "Available Upgrades" | wc -l)
    important_sec_count=$(yum --cacheonly --quiet list --updates --security --sec-severity {Critical,Important} 2>/dev/null | grep -v "Available Upgrades" | wc -l)
elif [ "$package_manager" = "apt" ]; then
    pkg_count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
    sec_count=$(apt list --upgradable 2>/dev/null | grep -cE "security|safety")
fi

# If updates available are listed as urgent, send alert
if ((important_sec_count > 0)); then
    printf "URGENT\n"
    printf "urgent: $important_sec_count\n"
    exit 1
fi

if ((sec_count > 0)); then
    printf "SECURITY\n"
    printf "security: $sec_count\n"
    exit 2
fi

if ((pkg_count > 0)); then
    printf "UPDATE\n"
    printf "packages: $pkg_count\n"
    exit 3
fi

printf "OK\n"
exit 0