# Fail2Ban Nagios / Icinga Plugin

Developer: Hamdy Abou El Anein
Contact: hamdy.aea@protonmail.com
License: GNU GPL v3 (see LICENSE).

A small Bash plugin that checks the number of **currently banned IP addresses**
in a Fail2Ban jail and prints Nagios-compatible status and performance data.

## Usage

```bash
./check_fail2ban_banned_ip.bash [jail-name]
# Default jail: sshd
./check_fail2ban_banned_ip.bash nginx-http-auth
```

It calls `fail2ban-client status <jail>` exactly once and parses the result.
The invoking user must have permission to query the Fail2Ban daemon.
For Nagios/Icinga, configure restricted access to the required command
instead of giving broad root permissions to a monitoring process.

| Exit code | State | Meaning |
|---|---|---|
| 0 | OK | No banned IPs |
| 2 | CRITICAL | At least one banned IP |
| 3 | UNKNOWN | Client missing, jail unavailable, invalid output or permission denied |

The output includes `| banned=N` for monitoring graphs. An inaccessible
Fail2Ban daemon is **never** mistaken for an empty ban list.

## Offline tests

```bash
bash -n check_fail2ban_banned_ip.bash
python3 -m unittest discover -s tests -v
```

The seven tests replace `fail2ban-client` with a mock executable; they
**never** query or modify the actual Fail2Ban configuration. No IPs are banned
or unbanned by the plugin.

The historical implementation is preserved in the Git branch `old`.
