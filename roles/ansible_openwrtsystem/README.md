# imp1sh.ansible\_openwrt.ansible\_openwrtsystem

Example of how to define system parameter for a host:
```yaml
openwrt_system_hostname: "n300.demo.junicast.de"
openwrt_system_description: "n300 Routing Node"
openwrt_system_notes: "Zusätzliche Infos hier"
openwrt_system_timezone: "CET-1CEST,M3.5.0,M10.5.0/3"
openwrt_system_zonename: "Europe/Berlin"
openwrt_system_logsize: "32"
openwrt_system_ntp_server:
  - "2.nl.pool.ntp.org"
  - "2.de.pool.ntp.org"
openwrt_system_ntp_enable_server: 1
openwrt_system_ntp_use_dhcp: 0
```

For more detailed information please have a look at the official [OpenWrt system configuration docs](https://openwrt.org/docs/guide-user/base-system/system_configuration).

## Variables

Unless noted otherwise, every variable is optional. Boolean/integer values accept both quoted (`"1"`) and unquoted (`1`) forms; UCI stores everything as strings and the consuming init scripts compare textually, so the two are interchangeable. Quoting is recommended to avoid YAML silently coercing words like `yes`/`no`/`on`/`off`/`true`/`false`.

### General

| Variable | Type | Valid values | Default | Description |
|---|---|---|---|---|
| `openwrt_system_hostname` | string | RFC 1123 hostname, ≤253 chars | `OpenWrt` | Device hostname. May be an FQDN-style dotted name. |
| `openwrt_system_description` | string | any | – | Free-form device description (LuCI metadata). |
| `openwrt_system_notes` | string | any | – | Free-form notes (LuCI metadata). |
| `openwrt_system_ttylogin` | bool | `0`, `1` | `1` | Require login on serial/console. See *Console login* below. |
| `openwrt_system_urandom_seed` | string | filepath or `0` | – | Seed file for `/dev/urandom` entropy persistence. `0` disables. |
| `openwrt_system_compat_version` | string | e.g. `1.0` | – | Config schema version for OpenWrt migration scripts. Usually should not be managed manually. |
| `openwrt_system_clock_timestyle` | bool | `0`, `1` | `0` | LuCI display: `0`=timezone offset (e.g. GMT+1), `1`=full timezone name. |
| `openwrt_system_clock_hourcycle` | string | `""`, `h12`, `h23` | `""` | LuCI display: hour cycle. Empty defers to browser locale. |
| `openwrt_system_zram_comp_algo` | string | `lzo`, `lz4`, `zstd` | `lzo` | ZRam compression algorithm. |
| `openwrt_system_zram_size_mb` | uint | ≥0 | – | ZRam device size in MiB. |

### Timezone

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_system_timezone` | string | `GMT0` | POSIX TZ string written to `/tmp/TZ`. |
| `openwrt_system_zonename` | string | `UTC` | IANA zone name (e.g. `Europe/Berlin`); links `/usr/share/zoneinfo/<zone>` to `/tmp/localtime` when available. |

### Logging

These options populate the `system` section consumed by `logd`/`logread` (`/etc/init.d/log`).

| Variable | Type | Valid values | Default | Description |
|---|---|---|---|---|
| `openwrt_system_log_proto` | string | `udp`, `tcp` | `udp` | Protocol for remote syslog forwarding. |
| `openwrt_system_log_trailer_null` | bool | `0`, `1` | `0` | Append a NUL trailer to each forwarded TCP message. |
| `openwrt_system_log_remote` | bool | `0`, `1` | `1` | Enable forwarding to a remote syslog server. |
| `openwrt_system_log_ip` | host | IP/hostname | – | Remote syslog server address. |
| `openwrt_system_log_port` | port | 1–65535 | `514` | Remote syslog server port. |
| `openwrt_system_log_hostname` | string | hostname | – | Hostname sent in remote syslog packets; defaults to kernel hostname if unset. |
| `openwrt_system_logfile` | string | filepath | – | Write a copy of the log to this file. |
| `openwrt_system_log_prefix` | string | any | – | Prefix prepended to each remotely-forwarded message. |
| `openwrt_system_logsize` | uint | ≥0 | – | Ring-buffer size in KiB (`log_size` in UCI). |
| `openwrt_system_log_buffer_size` | uint | ≥0 | – | Daemon-side logd buffer in KiB (`log_buffer_size` in UCI). Falls back to `logsize` when 0. |
| `openwrt_system_buffersize` | uint | ≥0 | – | Kernel printk ring buffer size (`dmesg -s`). |
| `openwrt_system_conloglevel` | uint | 1–8 | – | Console log level (`dmesg -n`); 8=debug … 1=emergency. |
| `openwrt_system_cronloglevel` | enum | `5`, `7`, `9` | – | Cron log level: 7=normal, 5=debug, 9=disabled. |

### NTP

Options for the `timeserver` (`ntp`) section consumed by `sysntpd`. The entire NTP block is only rendered when at least one of these variables is defined.

| Variable | Type | Valid values | Default | Description |
|---|---|---|---|---|
| `openwrt_system_ntp_server` | list[string] | non-empty list of hostnames/IPs | – | Upstream NTP server candidates. |
| `openwrt_system_ntp_enabled` | bool | `0`, `1` | `1` | Enable the NTP client. |
| `openwrt_system_ntp_enable_server` | bool | `0`, `1` | `0` | Act as an NTP server for LAN clients. |
| `openwrt_system_ntp_use_dhcp` | bool | `0`, `1` | `1` | Learn NTP servers advertised via DHCP. |
| `openwrt_system_ntp_interface` | string | UCI interface name | – | Bind the NTP server listener to this interface. Implied all-interfaces when unset. |
| `openwrt_system_ntp_dhcp_interface` | list[string] | non-empty list of UCI interface names | – | Interfaces to subscribe to for DHCP-advertised NTP servers. |

### LEDs

`openwrt_system_led` is a list of dictionaries defining `config led` sections.

| Dict key | Type | Required | Description |
|---|---|---|---|
| `itemname` | string | yes | Section name (UCI index). |
| `name` | string | yes | Human-readable LED label. |
| `sysfs` | string | yes | Sysfs LED path, e.g. `green:status`. |
| `trigger` | string | yes | Trigger type, e.g. `heartbeat`, `netdev`, `timer`. |
| `ports` | list[string] | no | Port(s) for `switchport`/`netdev` triggers. |
| `mode` | string | no | Link mode bitmask for `netdev` trigger. |
| `dev` | string | no | Device name for `netdev`/`usbdev` triggers. |

Example:
```yaml
openwrt_system_led:
  - itemname: led_wlan
    name: "WLAN"
    sysfs: "green:wlan"
    trigger: "netdev"
    dev: "wlan0"
    mode: "link tx rx"
```

## Differences to stock OpenWrt
### Console login

The variable `openwrt_system_ttylogin` defaults to `1`, thus it is required to enter credentials in order to be able to get a prompt. So if you connect via KVM or serial, remember to have your password. This seems crucial to me in order to get a minimum amount of security around OpenWrt. If you set this variable to `0` it reverts back to the OpenWrt default.

### Kernel logging to console
Kernel error messages are prompted to STDERR in a stock OpenWrt. Since this can be overwhelmingly annoying this role defaults to disable this feature. If you would like to revert back to OpenWrt default, set `openwrt_system_kernellogonconsole` to `true`.
When firewall logging is enabled expect the screen to be flooded

## Deployment internals

Low-level knobs for where the generated config lands and how the role behaves in build pipelines. Override only when targeting an Image Builder/chroot layout.

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_system_deployroot` | string | `/` | Root prefix for all deploy paths. |
| `openwrt_system_deploypath` | string | `<deployroot>etc/config` | Destination directory for `system` UCI file. |
| `openwrt_system_deployfile` | string | `system` | Filename of the `system` UCI config. |
| `openwrt_system_deploypath_kernellogging` | string | `<deployroot>etc/sysctl.d` | Destination dir for the kernel-printk suppression file. |
| `openwrt_system_deployfile_kernellogging` | string | `kernellogging.conf` | Filename of the kernel-printk config. |
| `openwrt_system_deploypath_sysctl` | string | `<deployroot>etc` | Destination dir for `sysctl.conf`. |
| `openwrt_system_deployfile_sysctl` | string | `sysctl.conf` | Filename of the sysctl overrides. |
| `openwrt_system_kernellogonconsole` | bool | `false` | Leave kernel printk-to-console at OpenWrt defaults instead of suppressing it. |
| `openwrt_system_runimagebuilder` | bool | `false` | Skip service-restart handlers (Image Builder/chroot mode). |
| `openwrt_imagebuilder_buildhost` | string | – | External host to delegate rendering/deploy to when building images elsewhere. Provided by the caller play, not this role. |

## Kernel Parameters
You can also set other kernel parameters with this role:

**Kernel parameter**: [net.netfilter.nf_conntrack_acct](https://ipset.netfilter.org/iptables-extensions.man.html)
Ansible variable: *openwrt_system_nf_conntrack_acct*

**Kernel parameter**: [net.netfilter.nf_conntrack_checksum](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_checksum*

**Kernel parameter**: [net.netfilter.nf_conntrack_max](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_max*
This value is quite important when you have plenty of parallel connections. A good example is NTP or torrent. In such cases you should adjust the value otherwise new connections will be stalled.

**Kernel parameter**: [net.netfilter.nf_conntrack_tcp_timeout_established](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_tcp_timeout_established*

**Kernel parameter**: [net.netfilter.nf_conntrack_udp_timeout](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_udp_timeout*

**Kernel parameter**: [net.netfilter.nf_conntrack_udp_timeout_stream](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_udp_timeout_stream*
