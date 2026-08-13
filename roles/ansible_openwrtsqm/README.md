# imp1sh.ansible_managemynetwork.ansible_openwrtsqm

Installs and configures [SQM](https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm) (Smart Queue Management) traffic shaping on OpenWrt devices. SQM combats bufferbloat by managing the egress and ingress queues on WAN-facing interfaces.

## Features

- Installs `sqm-scripts` and `luci-app-sqm` packages automatically (on-target via `ansible_packages` role, or merges them into `packages_installimagebuilder` for ImageBuilder flows)
- Renders `/etc/config/sqm` from a simple dictionary
- Supports multiple SQM instances (one per interface)
- Restarts the SQM service on config change
- Compatible with ImageBuilder deployments

## Requirements

Requires the `imp1sh.ansible_managemynetwork.ansible_packages` role to be available (called automatically by this role).

## Important: Flow Offloading Incompatibility

**SQM and hardware/software flow offloading are mutually exclusive.** Flow offloading bypasses the Linux qdisc layer where cake/fq_codel operates, causing offloaded packets to skip shaping entirely. This leads to inconsistent behaviour where some traffic is shaped and some is not.

If you use this role, ensure that flow offloading is disabled in your firewall config:

```
# /etc/config/firewall
config defaults 'syn_flood'
    option flow_offloading '0'
    option flow_offloading_hw '0'
```

Some newer OpenWrt versions support partial offloading that excludes the WAN interface while still offloading LAN-to-LAN traffic. However, this is not universally reliable — verify carefully if you attempt it.

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `openwrt_sqm_interfaces` | yes | — | Dictionary of SQM queue instances. Each key becomes the UCI section name. The role does nothing if this is undefined. |
| `openwrt_sqm_deployroot` | no | `/` | Root path for config deployment. Override for ImageBuilder or chroot scenarios. |
| `openwrt_sqm_runimagebuilder` | no | `false` | Set to `true` for ImageBuilder flows. Usually inferred automatically when `openwrt_imagebuilder_deployroot` is defined. |

## Per-Instance Options

Each entry in `openwrt_sqm_interfaces` supports the following keys:

| Key | Required | Default | Description |
|-----|----------|---------|-------------|
| `interface` | **yes** | — | Name of the interface to shape (e.g. `pppoe-wan`, `eth0`). Must be a real interface name as shown by `ip link`. |
| `upload` | **yes** | — | Upload bandwidth ceiling in kbit/s. Set ~5% below actual sync rate to avoid bufferbloat at the modem. |
| `download` | **yes** | — | Download bandwidth ceiling in kbit/s. Set ~5% below actual sync rate. |
| `qdisc` | no | `cake` | Queue discipline. Alternatives: `fq_codel`, `cobalt`, etc. |
| `script` | no | `piece_of_cake.qos` | SQM shaping script. Alternatives: `layer_cake.qos`, `simple_cake.qos`, etc. See [SQM docs](https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm). |
| `linklayer` | no | `none` | Link-layer overhead compensation. Use `ethernet` for wired links, `atm` for ATM/ADSL, `none` to disable. |
| `overhead` | no | `0` | Per-packet overhead in bytes. Critical for accurate shaping on VDSL/PPPoE/VLAN. See [overhead calculator](https://www.bufferbloat.net/projects/bloat/wiki/Adjusting_Cake/). |
| `enabled` | no | `1` | Enable (`1`) or disable (`0`) this SQM instance without removing the config. |
| `debug_logging` | no | `0` | Enable verbose SQM script logging (`0`/`1`). Useful for troubleshooting. |
| `verbosity` | no | `5` | Logging verbosity level (0-10). Higher values produce more output. |

## Naming Restrictions

The dictionary key (UCI section name) **may not contain a hyphen** (`-`). UCI section names with hyphens break the SQM init script. Stick to alphanumerics and underscores.

## Choosing the Right Interface

Attach SQM to the highest-level interface that carries IP traffic:

| Topology | Correct interface | Wrong |
|----------|-------------------|-------|
| VDSL + PPPoE + VLAN | `pppoe-wan` | ~~`dsl0`~~, ~~`dsl0.7`~~ |
| VDSL + VLAN (IP direct) | `dsl0.7` | ~~`dsl0`~~ |
| Cable/Ethernet WAN | `eth0` or `wan` | — |
| LTE/modem (PPP) | `pppoe-wan` | ~~`wwan0`~~ |

Attaching at the top of the stack lets you compensate for all lower-layer framing via the `overhead` parameter in one place.

## Common Overhead Values

| Connection type | overhead | Framing accounted for |
|-----------------|----------|----------------------|
| Ethernet (plain) | 18 | Ethernet header + CRC |
| PPPoE (Ethernet) | 38 | Ethernet(18) + PPPoE(8) + SNAP/AAL5(12) |
| VDSL2 PTM + PPPoE + VLAN | 44 | Ethernet(14) + VLAN(4) + PPPoE(8) + PTM(18) |
| VDSL2 PTM + PPPoE (no VLAN) | 40 | Ethernet(14) + PPPoE(8) + PTM(18) |
| ADSL2+ PPPoA LLC/Snap | 44 | Depends on encapsulation |

Always verify with a [bufferbloat test](https://www.waveform.com/tools/bufferbloat) after applying SQM. If latency spikes under load, adjust overhead or trim speed ceilings.

## Dependencies

None. Package installation is handled internally via `ansible_packages` role.

## Example Configuration

### VDSL2 100/40 Mbps with PPPoE + VLAN 7

```yaml
openwrt_sqm_interfaces:
  wan:
    interface: "pppoe-wan"
    qdisc: "cake"
    script: "piece_of_cake.qos"
    linklayer: "ethernet"
    overhead: 44
    upload: 35000
    download: 90000
    enabled: "1"
    debug_logging: "0"
    verbosity: "5"
```

### Cable Internet 1000/50 Mbps

```yaml
openwrt_sqm_interfaces:
  wan:
    interface: "eth0"
    qdisc: "cake"
    script: "piece_of_cake.qos"
    linklayer: "ethernet"
    overhead: 18
    upload: 47000
    download: 940000
```

## License

BSD-3-Clause
