# imp1sh.ansible_managemynetwork.ansible_openwrtnetwork

> [!WARNING]  
> python3-netaddr needs to be installed for this role

This role configures network interfaces in OpenWrt while not all interface types are supported just yet. This is me trying to assemble a list of what's supported so far. The most comprehensive list so far is [this](https://openwrt.org/docs/guide-user/network/wan/wan_interface_protocols).
- static
- dhcp
- dhcpv6
- wireguard
- pppoe
- ppp

Known to be MISSING:
- pppoa
- 3g
- qmi
- ncm
- wwan

As OpenWrt's documentation is surprisingly thin when it comes to fully listing all different interface options what I would need was a complete list of options and to what options they associate with. If you consider to assist with completing interface type support, do it in a tidy fashion as it is really hard to overlook what UCI options are available where.

You can define interfaces in ansible, either
- per host via `openwrt_network_interfaceshost` 
- per group via `openwrt_network_interfacesgroup`
The same is valid for 
- `openwrt_network_devices` and
- `openwrt_network_bridge_vlan`

The group based variables are being defined in group_vars section `group_vars/allhosts.yml`
The variables that are on group basis are being merged in the role. In order for that to work, you need to make assignment, like in the example:
```yaml
openwrt_network_devicesgroup:
  pplznet_missmarple:
    br-lan:
      type: "bridge"
      ports:
        - "eth0"
openwrt_network_interfacesgroup:
  pplznet_missmarple:
    lan:
      device: "br-lan"
      proto: "static"
      ipaddr:
        - "192.168.1.1/24"
      ip6assign: "64"
    wan:
      device: "eth1"
      proto: "dhcp"
    wan6:
      device: "@wan"
      proto: "dhcpv6"
    dmz:
      device: "eth2"
      proto: "static"
      ipaddr:
        - "192.168.2.1/24"
      ip6assign: 64
    guests:
      device: "eth3"
      proto: "static"
      ipaddr:
        - "192.168.3.1/24"
      ip6assign: 64
```

# Global Parameters
You can define ULA IPv6 and global packet steering on a global level.
```yaml
openwrt_network_globals_ula: "fd8d:2afe:fa38::/48"
openwrt_network_globals_packet_steering: 1

```

# Devices
Since 21.02 devices reference the phyiscal interfaces present in a device. Please have a look into the official OpenWrt network documentation [devices subsection](https://openwrt.org/docs/guide-user/base-system/basic-networking#device_sections).

This is a list of parameters:
* txqueuelen
* dadtransmits
* promisc
* rpfilter
* acceptlocal
* sendredirects
* neighreachabletime
* neighgcstaletime
* neighlocktime
* multicast
* igmpversion
* mldversion

Bridge Parameters:
* vlan_filtering
* igmp_snooping
* multicast_querier
* query_interval
* query_response_interval
* last_member_interval
* hash_max
* robustness
* stp
* forward_delay
* hello_time
* priority
* ageing_time
* max_age
* bridge_empty
* ports

## Static Bridge

mtu is optional, defaults to 1500 bytes.

```yaml
openwrt_network_deviceshost:
  br-lan:
    type: "bridge"
    ports:
      - "eth0"
    mtu: "9000"
    mtu6: "9000"
  eth1:
  eth2:
    mtu: "9000"
    mtu6: "9000"
```

## VLAN aware Bridge

```yaml
openwrt_network_deviceshost:
  mainbridge:
    type: "bridge"
    bridge_empty: "1"
    vlan_filtering: "1"
    ports:
      - "eth0"
      - "eth1"
      - "eth2"
      - "eth3"
```

In order to assign VLAN you use the 'openwrt_network_bridge_vlanhost' variable:
* **t** is Tagged
* **u** is untagged
* **\*** is for primary VLAN ID

```yaml
openwrt_network_bridge_vlanhost:
  - device: "mainbridge"
    vlan: "5"
    vlaninfo: "Netz1"
    ports:
      - "eth3:t"
      - "eth0:u*"
  - device: "mainbridge"
    vlan: "12"
    vlaninfo: "Freifunk Guests"
    ports:
      - "eth3:t"
      - "eth1:u*"
  - device: "mainbridge"
    vlan: "13"
    vlaninfo: "DMZ"
    ports:
      - "eth3:t"
  - device: "mainbridge"
    vlan: "61"
    vlaninfo: "Drucker"
    ports:
      - "eth3:t"
      - "eth2:u*"
  - device: "mainbridge"
    vlan: "62"
    vlaninfo: "Management"
    ports:
      - "eth3:t"
  - device: "mainbridge"
    vlan: "63"
    vlaninfo: "kids"
    ports:
      - "eth3:t"
```

## Vlan Device

```yaml
openwrt_network_deviceshost:
  eth3.5:
    type: "8021q"
    vid: 5
    vlaninfo: "insecure network"
    ifname: "eth3"

```

# Interfaces

Interfaces are a logical element that is being used to assign an IP configuration. Interfaces are being associated with devices. A device can be a real device or a virtual device, like a VLAN device, see above.
For a complete list of options, see [OpenWrt Wiki basic networking](https://openwrt.org/docs/guide-user/base-system/basic-networking#interface_sections).

## DHCP

```yaml
openwrt_network_interfaceshost:
  MGMT:
    device: "mainbridge.62"
    proto: "dhcp"
  MGMT6:
    device: "@MGMT"
    proto: "dhcpv6"
    reqaddress: "try"
    reqprefix: "auto"
  INSECURE:
    device: "mainbridge.5"
    proto: "none"
  SECURE:
    device: "mainbridge.61"
    proto: "none"

```

## Static IP

```yaml
openwrt_network_interfaceshost:
  wan:
    device: "eth0"
    proto: "static"
    ipaddr:
      - "1.2.3.4/28"
      - "1.244.24.2/32"
    gateway: "1.2.3.5"
    ip6addr:
      - "2a1a:1220:1:4f::4/64"
      - "2a01:fef0:1234:4f::b1b1/128"
    ip6gw: "2a1a:1220:1:4f::1"
    dns:
      - "2ae0:3fe1::2
      - "2ae0:3fe1::3"
    dnssearch:
      - "libcom.de"

```

## Loopback IPs

```yaml
openwrt_network_interfaceshost:
  loopback0:
    device: "@loopback"
    proto: "static"
    ip6addr:
      - "2a00:fe0:3f:4::1/128"

```

## PPPoE
```yaml
  wan:
    device: "eth0"
    proto: "pppoe"
    username: "PPPOE_username"
    password: "ASDF1234"
  wan6:
    device: "@wan"
    proto: "dhcpv6"
    reqaddress: "try"
    reqprefix: 48
```

# Static routes

You can implement static routes by using the `openwrt_network_staticroutes4` and `openwrt_network_staticroutes6` variables. Available attributes of this list var are documented in [OpenWrt's docs](https://openwrt.org/docs/guide-user/network/routing/routes_configuration). Examples:

```
openwrt_network_staticroutes4:
  - interface: "mgmt"
    comment: "static route telekom"
    target: "0.0.0.0/0"
    gateway: "192.168.1.2"
openwrt_network_staticroutes6:
  - interface: "secure"
    comment: "static route byd battery"
    target: "192.168.16.0/24"
    gateway: "10.123.11.2"
```

# Wireguard

This role supports configuration of wireguard interfaces. In OpenWrt they are normal interfaces that will also be assigned to a firewall zone.
Here are the most important options for

**Peer**
| Option | Description |
| - | - |
| interface | You need to reference a wireguard interface. Without that a peer definition is useless. |
| remote_peer | This is only needed when Ansible manages the remote peer as well. This option will fetch the remote peer's public key for your config. |
| endpoint_host | Only needed when host is initiating the connection. Defines the host address to connect to. |
| endpoint_port | Only needed when host is initiating the connection. Defines the host port to connect to. |
| managekeys | Makes sure peer's keypairs are generated and managed by this role. If set to false make sure to generate and maintain your keys manually. See also [here](#ansible-manages-keys) |
| generateclientconfig | When set to yes it will generate your clientconfig in the directory defined in `openwrt_network_wg_keypath`. Only set this to true when `managekeys` is also set to true |
| mtu | self explanatory |
| persistent_keepalive | self explanatory |
| setpsk | If you set `setpsk` to `true` an additional PSK (Preshared Key)  will be used. |
| route_allowed_ips | self explanatory |
| allowed_ips | (list) self explanatory |
| description | self explanatory |
| public_key | public key of the remote remote peer. Only set when `managkeys` is set to false |
| preshared_key | preshared key for extra security. Only set manually when setpsk is set to false |

**Interface**
| Option | Description | Default |
| - | - | - |
| wg_private_key | Private key of your host used for wireguard | has no default |
| wg_listen_port | listening port | has no default |
| wg_addresses | (list) give ip addresses for the tunnel interface of your host | has no default |
| wg_peerdns | ? | ? |
| wg_nohostroute | if true (1)  no entries for routing table will be made | false (0) |
| wg_disabled | if set to true (1) wireguard interface will be disabled | false (0) |
| wg_auto | if set to false (0) interface won't come up automatically on boot | has no default |
| wg_force_link | Set interface properties regardless of the link carrier (If set, carrier sense events do not invoke hotplug handlers) | false (0) |
| wg_fwmark | Optional. 32-bit mark for packets during firewall processing. Enter value in hex, starting with 0x | has no default |
| wg_defaultroute | If set to false (0), no default route is configured | true (1) |
| wg_dns | (list) IP addresses of nameservers used | has no default |
| wg_dns_metric | The DNS server entries in the local resolv.conf are primarily sorted by the weight specified here | 0 |
| wg_metric | Metric is an ordinal, where a gateway with 1 is chosen 1st, 2 is chosen 2nd, 3 is chosen 3rd, etc | 0 |
| wg_ip4table | Override IPv4 routing table | by default main table will be used |
| wg_ip6table | Override IPv4 routing table | by default main table will be used |
| wg_delegate | Enable downstream delegation of IPv6 prefixes available on this interface | true (1) |
| wg_ip6assign | Assign a part of given length of every public IPv6-prefix to this interface | disabled (1) | 
| wg_ip6hint | Only set if wg_ip6assign is set too. Choose your prefix ID. Has to fit to the delegated prefix | has no default |
| wg_ip6class | Choose from which upstream interface the prefix is delegated from | has no default |
| wg_ip6ifaceid | Optional. Allowed values: 'eui64', 'random', fixed value like '::1' or '::1:2'. When IPv6 prefix (like 'a:b:c:d::') is received from a delegating server, use the suffix (like '::1') to form the IPv6 address ('a:b:c:d::1') for the interface | ::1 |
| wg_ip6weight | When delegating prefixes to multiple downstreams, interfaces with a higher preference value are considered first when allocating subnets. | 0 |

## Manage Keys manually
Example for a wireguard interface:

```yaml
openwrt_network_interfaceshost:
  ROADWARRIOR:
    proto: "wireguard"
    wg_managekeys: false
    wg_private_key: "theserversprivatekey"
    wg_myendpoint: "4.12.223.10"
    wg_listen_port: 51821
    wg_peerdns: 0
    wg_addresses:
      - "10.10.100.97/27"
      - "2a00:123:456:22::1/64"
```

This is an example for a wireguard peer:
```yaml
openwrt_network_wireguardpeers:
  peername:
    interface: "ROADWARRIOR"
    managekeys: false
    generateclientconfig: false
    public_key: "thepeerspublickey"
    preshared_key: "thepresharedkey"
    setpsk: false
    allowed_ips:
      - "2a00:123:688:11::2/128"
      - "10.10.100.2/32"
```
> [!WARNING]  
> The interface attribute above references an interface name, specified in `openwrt_network_interfaces`.

## Ansible manages keys
> [!WARNING]  
> If you would like to use that you need the wireguard tools installed on the Ansible host.

Since 0.1.4 this role is able to manage the keys within Ansible. Keys are being stored on the ansible host.
You can specify the directory with this variable:`openwrt_network_wg_keypath`.
e.g.
```yaml
openwrt_network_wg_keypath: "/home/ansibleuser/wireguard"
```

Default is `/etc/wireguard/ansiblekeys` which should be adjusted because the target directory may not be writeable by the Ansible user. The user you run Ansible with, needs permissions in this directory.

If you would like to import keys, store them within the `wg_keypath` directory.

```
./<<wireguard Interfacename>>/<<ansible_hostname>>_private.key
./<<wireguard Interfacename>>/<<ansible_hostname_public.key
./<<wireguard Interfacename>>/<<peername>>_public.key
./<<wireguard Interfacename>>/<<peername>>_private.key
./<<wireguard Interfacename>>/S2S.psk
./<<wireguard Interfacename>>/<<peername>>.psk
./<<wireguard Interfacename>>/<<peername>>.conf
```
> [!WARNING]  
> Your private keys are sensitive. Use secure permissions. Make sure they can't be accessed by third parties.

If you would like to let Ansible manage keys, set the `managekeys` var to true.

```yaml
openwrt_network_wireguardpeers:
  peername:
    interface: "ROADWARRIOR"
    genclientconfig: true
    mtu: 1360
    managekeys: true
    setpsk: true
    allowed_ips:
      - "2a00:123:688:11::2/128"
      - "10.10.100.2/32"
    routes_to:
      - "172.16.0.0/12"
      
openwrt_network_interfaceshost:
  ROADWARRIOR:
    proto: "wireguard"
    wg_managekeys: true
    wg_listen_port: 51821
    wg_peerdns: 0
    wg_addresses:
      - "10.10.100.97/27"
      - "2a00:123:456:22::1/64"
```

The MTU is at 1420 as a default. I can be overwritten with the `mtu` property.
If you want additional routes inserted into the client config, use the `routes_to` variable (list).

### Site 2 Site VPN

Managing keys in a Site 2 Site (S2S) setup is different. Ansible will fully manage configuration and keys for both sites for you.
In `openwrt_network_wireguardpeers` the flag `s2s` needs to be `true`:

```yaml
  remotepeer1.example.com:
    interface: "S2S_tunnel1"
    s2s: true
    remote_peer: "remotepeer1.example.com"
    managekeys: true
    setpsk: true
    endpoint_host: "2001:1234:fefe:28d4::d3ad"
    endpoint_port: 51821
    route_allowed_ips: 1
    allowed_ips:
      - "10.10.128.0/20"
      - "2001:4444:2333::/48"
```

Consider that the PSK needs to be identical on both sides. Otherwise both would be different, which would not work.
Another specialty is naming the peer via `openwrt_network_wireguardpeers`. The name has to correspond to the ansible special variable `inventory_hostname` of the other peer.

peera.example.com <- Site 2 Site -> peerb.example.com
```yaml
openwrt_network_wireguardpeers:
  peera.example.com:
    managekeys: true
    s2s: true
    ...
```
or
```yaml
openwrt_network_wireguardpeers:
  peerb.example.com:
    managekeys: true
    s2s: true
    ...
```
