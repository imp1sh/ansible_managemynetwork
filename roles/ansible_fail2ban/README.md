# ansible_fail2ban

Installs and configures fail2ban with a three-tier variable merge pattern
(default → group → host) and an optional Prometheus metrics exporter that
writes to the node_exporter textfile collector directory.

## Variable merge pattern

Following the `ansible_openwrtfirewall` convention, variables are merged
across three layers:

| Layer | Suffix | Location | Precedence |
|-------|--------|----------|------------|
| Default | `*default` | role `defaults/main.yml` | lowest |
| Group | `*group` (keyed by group name) | `group_vars/` | middle |
| Host | `*host` | `host_vars/` | highest |

Dicts (jails, settings) are combined with `recursive=true` so a host can
override a single parameter of a jail without redeclaring the whole stanza.
Lists (ignoreip) are concatenated.

## Variables

See `defaults/main.yml` for the full list. Key ones:

- `fail2ban_backend` — `systemd` (recommended for Trixie), `polling`, `auto`
- `fail2ban_banaction` — `nftables-multiport` (native nft, self-contained table)
- `fail2ban_bantime_increment` — escalate ban duration for repeat offenders (default: true)
- `fail2ban_bantime_factor` — multiplier per repeat offense (default: 2)
- `fail2ban_bantime_maxtime` — cap for escalated bans (default: 1w)
- `fail2ban_jailsdefault` / `fail2ban_jailsgroup` / `fail2ban_jailshost` — jail definitions
- `fail2ban_ignoreipdefault` / `fail2ban_ignoreipgroup` / `fail2ban_ignoreiphost` — whitelist
- `fail2ban_exporter_enabled` — deploy the Prometheus metrics exporter (default: true)
- `fail2ban_exporter_interval` — systemd timer interval (default: 30s)
- `fail2ban_exporter_textfile_dir` — node_exporter textfile collector path

## Metrics

Exports four gauges with a `jail` label via the node_exporter textfile collector:

```
fail2ban_failed_current{jail="sshd"}
fail2ban_failed_total{jail="sshd"}
fail2ban_banned_current{jail="sshd"}
fail2ban_banned_total{jail="sshd"}
```

Based on [jangrewe/prometheus-fail2ban-exporter](https://github.com/jangrewe/prometheus-fail2ban-exporter).
