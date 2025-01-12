# imp1sh.ansible_managemynetwork.ansible_openwrtusteer

This role configures usteeer package on OpenWrt devices.

This role can be used with ImageBuilder. To enable this, set `openwrt_usteer_runimagebuilder` to `true`.

To configure this role, set the `openwrt_usteer_config` variable to a dictionary containing the desired usteer options. Detailed descriptions of these options can be found in the [usteer documentation](https://openwrt.org/docs/guide-user/network/wifi/usteer).

## Example Configuration

```yaml
openwrt_usteer_config:
  network: lan
  syslog: 1
  local_mode: 0
  ipv6: 0
  debug_level: 2
  roam_scan_snr: -55
  signal_diff_threshold: 10
  ssid_list:
    - "ExampleSSID"
```
