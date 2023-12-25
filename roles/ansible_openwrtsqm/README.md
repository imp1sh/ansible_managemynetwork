# imp1sh.ansible._managemynetwork.ansible_openwrtsqm

This role sets up SQM QoS traffic shaping, in Luci found at *Network- SQM QoS*.
For detailed documentation about this feature see [OpenWrt SQM docs](https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm).

A minimalistic configuration could look like this, on a VDSL2 100/40 Mbps line.

```
openwrt_sqm_interfaces:
  pppoe:
    interface: "pppoe-wan"
    linklayer: "ethernet"
    overhead: 34
    upload: 35000
    download: 90000

```
Multiple instances of sqm interfaces can be defined using this dictionary variable.

> Attention
> The interface name (here: pppoe) may not contain a hyphen. I cannot say what other characters are disallowed, too. Ideally don't use special characters, just alphanumeric.
{.is-warning}
