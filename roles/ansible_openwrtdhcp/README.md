# imp1sh.ansible_managemynetwork.ansible_openwrtdhcp
This role manages the integrated dnsmasq DHCP / DNS / Radvd and DHCPv6 Settings. Managing odhcp, bind or other alternative packages is currently not supported.

## Globale Parameters
Global parameters are documented in the [OpenWrt Wiki](https://openwrt.org/docs/guide-user/base-system/dhcp#common_options). OpenWrt utilizes dnsmasq. This is how the Ansible Variables look like.

```
openwrt_dhcp_dnsmasq_<<parameter name>>
```
for example
```
openwrt_dhcp_dnsmasq_filterwin2k
```

## DHCP Pools
This is an example of how to define a dhcp pool.

```yaml
openwrt_dhcp_poolshost:
  - name: "lan"
    ignore: "0"
    interface: "lan"
    start: "100"
    limit: "150"
    leasetime: "12h"
    dhcpv6: "server"
    ra: "server"
    ra_management: "1"
    ra_default: "1"
    domain:
      - "example.com"
    dhcp_option:
      - "6,10.10.133.111"
    dns:
      - "2620:fe::fe"
      - "2620:fe::fe:9"
    ra_flags:
      - "managed-config"
      - "other-config"
```
You can make definitions on group layer. This is not defined within the group itself but in the allhosts group (e.g. in `./host_vars/allhosts.yml`) like this.

```yaml
openwrt_dhcp_poolsgroup:
  testgroup:
    - name: "Guests"
      start: "100"
      end: "220"
      interface: "eth0"
```
Find more possible parameters in the [OpenWrt DHCP documentation](https://openwrt.org/docs/guide-user/base-system/dhcp).

## Static Leases

> The names of the leases may not contain spaces.
{.is-warning}

IPv4 example:
```
openwrt_dhcp_leases:
  - name: "voiptelefon1"
    mac: "00:04:13:aa:bb:cc"
    ip: "10.10.129.91"
    leasetime: "96h"
```
IPv6 example:
```
openwrt_dhcp_leases:
  - name: "voiptelefon2"
    duid: "fefefefefefefefefefefe"
    hostid: "fee"
    leasetime: "96h"
```
Dual Stack example:
```
openwrt_dhcp_leases:
  - name: "voiptelefon1"
    mac: "00:04:13:aa:bb:cc"
    ip: "10.10.129.91"
    duid: "fefafefaefefafefafefa"
    hostid: "fea"
    leasetime: "96h"
```
