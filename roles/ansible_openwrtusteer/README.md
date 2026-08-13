# imp1sh.ansible_managemynetwork.ansible_openwrtusteer

This role installs and configures the [usteer](https://openwrt.org/docs/guide-user/network/wifi/usteer) package on OpenWrt devices. Usteer is a roaming-assistant daemon that exchanges per-station signal data between access points and actively steers clients to better APs or bands.

## Features

- Installs `usteer` and `luci-app-usteer` packages automatically (on-target via `ansible_packages` role, or merges them into `packages_installimagebuilder` for ImageBuilder flows)
- Renders all UCI options supported by usteer from a single `openwrt_usteer_config` dictionary
- Restarts the usteer service on config change

## Requirements

Requires the `imp1sh.ansible_managemynetwork.ansible_packages` role to be available (called automatically by this role).

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `openwrt_usteer_config` | no | `{}` | Dictionary of usteer UCI options. An empty dict renders a minimal config with sensible defaults (`network=lan`, `syslog=1`, `local_mode=0`, `ipv6=0`, `debug_level=2`). |
| `openwrt_usteer_deployroot` | no | `/` | Root path for config deployment. Override for ImageBuilder or chroot scenarios. |
| `openwrt_usteer_runimagebuilder` | no | `false` | Set to `true` for ImageBuilder flows. Usually inferred automatically when `openwrt_imagebuilder_deployroot` is defined. |

Detailed descriptions of all usteer options can be found in the [official usteer documentation](https://openwrt.org/docs/guide-user/network/wifi/usteer).

## Supported UCI Options

The template supports all options documented in the official wiki plus several additional options exposed by `luci-app-usteer`:

`network`, `syslog`, `ipv6`, `local_mode`, `debug_level`, `max_neighbor_reports`, `sta_block_timeout`, `local_sta_timeout`, `measurement_report_timeout`, `local_sta_update`, `max_retry_band`, `seen_policy_timeout`, `load_balancing_threshold`, `band_steering_threshold`, `remote_update_interval`, `remote_node_timeout`, `assoc_steering`, `probe_steering`, `min_connect_snr`, `min_snr`, `min_snr_kick_delay`, `steer_reject_timeout`, `roam_process_timeout`, `roam_scan_snr`, `roam_scan_tries`, `roam_scan_timeout`, `roam_scan_interval`, `roam_trigger_snr`, `roam_trigger_interval`, `roam_kick_delay`, `signal_diff_threshold`, `initial_connect_delay`, `load_kick_enabled`, `load_kick_threshold`, `load_kick_delay`, `load_kick_min_clients`, `load_kick_reason_code`, `band_steering_interval`, `band_steering_min_snr`, `link_measurement_interval`, `node_up_script`, `event_log_types` (list), `ssid_list` (list), `aggressiveness`, `aggressiveness_mac_list` (list), `reassociation_delay`, `band_steering_signal_threshold`

## Dependencies

None. Package installation is handled internally via `ansible_packages` role.

## Example Configuration

```yaml
openwrt_usteer_config:
  network: lan
  syslog: 1
  debug_level: 2
  min_connect_snr: 20
  min_snr: 15
  min_snr_kick_delay: 5000
  roam_trigger_snr: 20
  roam_scan_snr: 25
  signal_diff_threshold: 5
  seen_policy_timeout: 300
  band_steering_threshold: 10
  initial_connect_delay: 200
  ssid_list:
    - "wasgeistreiches"
```

## License

BSD-3-Clause
