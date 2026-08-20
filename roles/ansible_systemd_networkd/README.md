# ansible_systemd_networkd

Configures systemd-networkd network interfaces, links, and netdevs (including
WireGuard) from simple dictionary variables. Deploys automatic DNS endpoint
management for WireGuard interfaces with dynamic endpoints.

## Origin

Forked from [stackhpc/ansible-role-systemd-networkd](https://github.com/stackhpc/ansible-role-systemd-networkd),
which itself adapts code from the [OpenStack ansible-role-systemd_networkd](https://github.com/openstack/ansible-role-systemd_networkd).
Original BSD-3-Clause license retained. Attribution: Anthony Ruhier, StackHPC Ltd,
OpenStack Foundation.

## Enhancements over upstream

### WireGuard endpoint DNS management

When a WireGuard `.netdev` specifies an `Endpoint` as a hostname (not an IP),
systemd-networkd resolves it **once** at interface creation time and never
updates it. This causes two problems:

1. **Boot race**: WG interface comes up before DNS is available — endpoint
   stays unresolved permanently, tunnel never connects.
2. **Dynamic endpoint**: server IP changes, DNS updates, but networkd keeps
   sending to the old cached IP forever.

This role detects WireGuard interfaces with hostname-based endpoints and
deploys two mechanisms per interface:

#### Boot refresh (`wg-endpoint-refresh-<iface>.service`)

A oneshot service that waits up to 30 seconds for DNS to become available
after boot, then runs `networkctl reconfigure <iface>` so networkd re-resolves
the endpoint. Ordered after `systemd-networkd-wait-online.service`.

#### Periodic DNS watcher (`wg-endpoint-watch-<iface>.timer`)

A timer that fires every `systemd_networkd_wireguard_watch_interval` seconds
(default 300). Runs a script that:
1. Resolves the endpoint hostname via `getent`
2. Compares to the current `wg show` endpoint IP
3. Calls `networkctl reconfigure <iface>` only when the IP actually changed

No interface restart, no tunnel flap, no needless reconfigure cycles. The
watcher is silent when the endpoint is unchanged.

Disable both with:
```yaml
systemd_networkd_wireguard_refresh: false
```

Tune the watch interval:
```yaml
systemd_networkd_wireguard_watch_interval: 120
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `systemd_networkd_link` | `{}` | Dict of `.link` files |
| `systemd_networkd_netdev` | `{}` | Dict of `.netdev` files (incl. WireGuard) |
| `systemd_networkd_network` | `{}` | Dict of `.network` files |
| `systemd_networkd_apply_config` | `false` | Restart systemd-networkd on config change |
| `systemd_networkd_enable_resolved` | `true` | Enable and start systemd-resolved |
| `systemd_networkd_symlink_resolv_conf` | `true` | Symlink `/etc/resolv.conf` to resolved stub |
| `systemd_networkd_cleanup` | `false` | Remove unexpected files in `/etc/systemd/network/` |
| `systemd_networkd_wireguard_refresh` | `true` | Deploy WG endpoint DNS refresh + watcher |
| `systemd_networkd_wireguard_watch_interval` | `300` | Seconds between endpoint DNS checks |

## License

BSD-3-Clause (retained from upstream)
