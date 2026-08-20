# ansible_systemd_networkd

Configures systemd-networkd network interfaces, links, and netdevs (including
WireGuard) from simple dictionary variables. Optionally deploys a oneshot
systemd service per WireGuard interface to fix a DNS race condition at boot.

## Origin

Forked from [stackhpc/ansible-role-systemd-networkd](https://github.com/stackhpc/ansible-role-systemd-networkd),
which itself adapts code from the [OpenStack ansible-role-systemd_networkd](https://github.com/openstack/ansible-role-systemd_networkd).
Original BSD-3-Clause license retained. Attribution: Anthony Ruhier, StackHPC Ltd,
OpenStack Foundation.

## Enhancements over upstream

### WireGuard endpoint DNS refresh

When a WireGuard `.netdev` specifies an `Endpoint` as a hostname (not an IP),
systemd-networkd resolves it **once** at interface creation time. If DNS is not
yet available — a common race when the physical interface uses DHCP/RA and
comes up simultaneously — the endpoint stays unresolved permanently and the
tunnel never connects.

This role detects WireGuard interfaces with hostname-based endpoints and deploys
a oneshot systemd service (`wg-endpoint-refresh-<iface>.service`) for each. The
service waits up to 30 seconds for DNS to become available, then runs
`networkctl reconfigure <iface>` so networkd re-resolves the endpoint.

Disable with:
```yaml
systemd_networkd_wireguard_refresh: false
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
| `systemd_networkd_wireguard_refresh` | `true` | Deploy WG endpoint DNS refresh services |

## License

BSD-3-Clause (retained from upstream)
