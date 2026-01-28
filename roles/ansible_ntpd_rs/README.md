# imp1sh.ansible_managemynetwork.ansible_ntpd_rs

Installs and configures [ntpd-rs](https://github.com/pendulum-project/ntpd-rs), a Rust-based NTP daemon.

## Requirements

This role is designed for Debian-based systems. It installs `ntpd-rs` from the official GitHub releases using `.deb` packages.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml` and `templates/ntp.toml.jinja2`):

### General Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ntpdrs_log_level` | `info` | Log level for the daemon. Options: `trace`, `debug`, `info`, `warn`, `error`. |
| `ntpds_metrics_enable` | *undefined* | Set to `true` to enable the `ntpd-rs-metrics` service. |
| `ntpdrs_observation_permissions` | *undefined* | Permissions for the observation socket. |
| `ntpdrs_metrics_exporter_listen` | *undefined* | Address and port for the metrics exporter to listen on. |

### NTP Sources

You can configure multiple sources using `ntpdrs_sources`.

```yaml
ntpdrs_sources:
  - mode: pool
    address: debian.pool.ntp.org
    count: 4   # Optional
    ignore:    # Optional, for pool mode
  - mode: server
    address: ntpd-rs.pool.ntp.org
  - mode: nts
    address: nts.netnod.se
    certificate_authority: /path/to/ca.pem # Optional
```

### Server Mode

To enable server mode (serving time to other clients), set `ntpdrs_server` (implicitly enabled if any server options are defined) or define:

| Variable | Default | Description |
|----------|---------|-------------|
| `ntpdrs_listen` | `[::]:123` | Address and port to listen on. |
| `ntpdrs_rate_limiting_cache_size` | *undefined* | Size of the rate limiting cache. |
| `ntpdrs_rate_limiting_cutoff_ms` | *undefined* | Cutoff for rate limiting in milliseconds. |
| `ntpdrs_require_nts` | *undefined* | Require NTS for clients. |

**Access Control:**

- `ntpdrs_server_allowlist`: List of subnets to allow.
- `ntpdrs_server_allowlist_action`: Action for allowlist (default: `ignore`).
- `ntpdrs_server_denylist`: List of subnets to deny.
- `ntpdrs_server_denylist_action`: Action for denylist (default: `deny`).

### Synchronization and Thresholds

| Variable | Default | Description |
|----------|---------|-------------|
| `ntpdrs_single_step_panic_threshold` | `1800` | Maximum step size (seconds) during normal operation. |
| `ntpdrs_startup_step_panic_threshold_forward` | `inf` | Startup forward jump limit. |
| `ntpdrs_startup_step_panic_threshold_backward` | `86400` | Startup backward jump limit. |
| `ntpdrs_accumulated_threshold` | *undefined* | Threshold for accumulated time jumps before stopping. |
| `ntpdrs_minimum_agreeing_sources` | *undefined* | Minimum number of agreeing sources required. |
| `ntpdrs_local_stratum` | *undefined* | Local stratum configuration. |
| `poll-interval-limits` | *undefined* | Poll interval limits (min, max). |
| `ntpdrs_initial_poll_interval` | *undefined* | Initial poll interval. |

## Dependencies

None.

## Example Playbook

```yaml
    - hosts: servers
      roles:
        - role: imp1sh.ansible_managemynetwork.ansible_ntpd_rs
          vars:
            ntpdrs_log_level: 'info'
            ntpdrs_sources:
              - mode: pool
                address: debian.pool.ntp.org
            ntpds_metrics_enable: true
```

## License

GPL-2.0-or-later

## Author Information

See `meta/main.yml` for author details.
