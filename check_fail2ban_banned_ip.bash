#!/usr/bin/env bash
# Developer: Hamdy Abou El Anein
# Contact: hamdy.aea@protonmail.com
# Copyright (C) 2026 Hamdy Abou El Anein
# SPDX-License-Identifier: GPL-3.0-or-later
# Nagios/Icinga plugin: inspect currently banned addresses in a Fail2Ban jail.
# Exit status: 0 OK, 2 CRITICAL, 3 UNKNOWN. A failed check is NEVER reported OK.
set -o pipefail

jail="${1:-sshd}"
if [[ "$jail" == "--help" || "$jail" == "-h" ]]; then
    printf 'Usage: %s [jail-name]\n' "${0##*/}"
    exit 0
fi
if [[ ! "$jail" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    printf 'UNKNOWN: invalid jail name\n'
    exit 3
fi
if ! command -v fail2ban-client >/dev/null 2>&1; then
    printf 'UNKNOWN: fail2ban-client is not installed | banned=U\n'
    exit 3
fi

# One invocation: avoid racing status changes and duplicate privileged calls.
if ! output="$(LC_ALL=C fail2ban-client status "$jail" 2>&1)"; then
    printf 'UNKNOWN: unable to query Fail2Ban jail %s | banned=U\n' "$jail"
    exit 3
fi
count=''
ips=''
while IFS= read -r line; do
    if [[ "$line" =~ Currently[[:space:]]banned:[[:space:]]*([0-9]+) ]]; then
        count="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ Banned[[:space:]]IP[[:space:]]list:[[:space:]]*(.*) ]]; then
        ips="${BASH_REMATCH[1]}"
    fi
done <<< "$output"
if [[ -z "$count" || ! "$count" =~ ^[0-9]+$ ]]; then
    printf 'UNKNOWN: invalid Fail2Ban status for %s | banned=U\n' "$jail"
    exit 3
fi
# Interpret the decimal count safely even if Fail2Ban adds leading zeros.
count=$((10#$count))
if (( count == 0 )); then
    printf 'OK: no IP banned in %s | banned=0\n' "$jail"
    exit 0
fi
if [[ -z "${ips//[[:space:]]/}" ]]; then
    printf 'UNKNOWN: %d banned in %s, but the IP list is missing | banned=%d\n' "$count" "$jail" "$count"
    exit 3
fi
# Fail2Ban emits addresses as a whitespace-delimited list; never evaluate them.
ips="${ips#"${ips%%[![:space:]]*}"}"
printf 'CRITICAL: %d IP(s) banned in %s: %s | banned=%d\n' "$count" "$jail" "$ips" "$count"
exit 2
