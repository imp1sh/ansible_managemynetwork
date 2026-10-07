# imp1sh.ansible_managemynetwork.ansible_openwrtnetwork

> [!WARNING]  
> python3-netaddr needs to be installed for this role

> [!TIP]
> You can skip the automatic restart if you set `openwrt_network_skiprestart=true`
> You can save your network config on the device by setting `openwrt_network_backupconfig=true`

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

As OpenWrt's documentation is surprisingly thin when it comes to fully listing all different interface options. If you consider to assist with completing interface type support, do it in a tidy fashion as it is really hard to overlook what UCI options are available.

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
Since 21.02 devices reference the physical interfaces present in a device. Please have a look into the official OpenWrt network documentation [devices subsection](https://openwrt.org/docs/guide-user/base-system/basic-networking#device_sections).

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
      - "2ae0:3fe1::2"
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
| allowed_ips | (list) self explanatory |
| description | self explanatory |
| endpoint_host | Optional. Overrides `wg_myendpoint` from the interface for client config generation. Defines the host address clients will connect to. If not set, uses `wg_myendpoint` from the interface. |
| endpoint_port | Optional. Overrides `wg_listen_port` from the interface for client config generation. Defines the port clients will connect to. If not set, uses `wg_listen_port` from the interface. |
| generateclientconfig | When set to yes it will generate your clientconfig in the directory defined in `openwrt_network_wg_keypath`. Only set this to true when `managekeys` is also set to true |
| interface | You need to reference a wireguard interface. Without that a peer definition is useless. |
| managekeys | Makes sure peer's keypairs are generated and managed by this role. If set to false make sure to generate and maintain your keys manually. See also [here](#ansible-manages-keys) |
| mtu | self explanatory |
| keepalive | Used for client config generation. Sets PersistentKeepalive value (in seconds) to keep NAT mappings alive. Typically set to 25 for clients behind NAT. |
| persistent_keepalive | Used for server-side peer configuration. Sets persistent keepalive interval (in seconds) when the server initiates connections. |
| preshared_key | preshared key for extra security. Only set manually when setpsk is set to false |
| public_key | public key of the remote remote peer. Only set when `managekeys` is set to false |
| remote_peer | Required when `managekeys` is `true` and `generateclientconfig` is `true`. For roadwarrior setups, set this to `{{ inventory_hostname }}` (the server's hostname) so Ansible can fetch the server's public key for client config generation. For S2S setups, set this to the remote peer's hostname. |
| route_allowed_ips | self explanatory |
| setpsk | If you set `setpsk` to `true` an additional PSK (Preshared Key)  will be used. |

**Interface**
| Option | Description | Default |
| - | - | - |
| wg_addresses | (list) give ip addresses for the tunnel interface of your host | has no default |
| wg_auto | if set to false (0) interface won't come up automatically on boot | has no default |
| wg_defaultroute | If set to false (0), no default route is configured | true (1) |
| wg_delegate | Enable downstream delegation of IPv6 prefixes available on this interface | true (1) |
| wg_disabled | if set to true (1) wireguard interface will be disabled | false (0) |
| wg_dns | (list) IP addresses of nameservers used | has no default |
| wg_dns_metric | The DNS server entries in the local resolv.conf are primarily sorted by the weight specified here | 0 |
| wg_force_link | Set interface properties regardless of the link carrier (If set, carrier sense events do not invoke hotplug handlers) | false (0) |
| wg_fwmark | Optional. 32-bit mark for packets during firewall processing. Enter value in hex, starting with 0x | has no default |
| wg_ip4table | Override IPv4 routing table | by default main table will be used |
| wg_ip6assign | Assign a part of given length of every public IPv6-prefix to this interface | disabled (1) | 
| wg_ip6class | Choose from which upstream interface the prefix is delegated from | has no default |
| wg_ip6hint | Only set if wg_ip6assign is set too. Choose your prefix ID. Has to fit to the delegated prefix | has no default |
| wg_ip6ifaceid | Optional. Allowed values: 'eui64', 'random', fixed value like '::1' or '::1:2'. When IPv6 prefix (like 'a:b:c:d::') is received from a delegating server, use the suffix (like '::1') to form the IPv6 address ('a:b:c:d::1') for the interface | ::1 |
| wg_ip6table | Override IPv4 routing table | by default main table will be used |
| wg_ip6weight | When delegating prefixes to multiple downstreams, interfaces with a higher preference value are considered first when allocating subnets. | 0 |
| wg_listen_port | listening port | has no default |
| wg_metric | Metric is an ordinal, where a gateway with 1 is chosen 1st, 2 is chosen 2nd, 3 is chosen 3rd, etc | 0 |
| wg_myendpoint | Used as information for client config generation. Endpoint client will connect to | |
| wg_nohostroute | if true (1)  no entries for routing table will be made | false (0) |
| wg_peerdns | If set to 1, DNS servers received from peers will be used. If set to 0, peer-provided DNS servers are ignored. Typically set to 0 for server interfaces. | 0 |
| wg_private_key | Private key of your host used for wireguard | has no default |

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
> Have wireguard tools installed on the Ansible controller host!

This role can manage the keys via Ansible. Keys are being stored on the Ansible controller host. You can specify the directory with this variable:`openwrt_network_wg_keypath`.
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

### Roadwarrior Setup

For a roadwarrior (client-to-server) setup where the OpenWrt router acts as the server and mobile devices connect as clients:

```yaml
openwrt_network_wireguardpeers:
  mylaptop:
    interface: "ROADWARRIOR"
    generateclientconfig: true
    mtu: 1360
    managekeys: true
    setpsk: true
    remote_peer: "{{ inventory_hostname }}"
    keepalive: 25
    allowed_ips:
      - "2a00:123:688:11::2/128"
      - "10.10.100.2/32"
    routes_to:
      - "172.16.0.0/12"
    # Optional: Override endpoint if different from interface settings
    # endpoint_host: "vpn.example.com"
    # endpoint_port: 51821
      
openwrt_network_interfaceshost:
  ROADWARRIOR:
    proto: "wireguard"
    wg_managekeys: true
    wg_myendpoint: "vpn.example.com"
    wg_listen_port: 51821
    wg_peerdns: 0
    wg_addresses:
      - "10.10.100.97/27"
      - "2a00:123:456:22::1/64"
```

**Important notes for roadwarrior setup:**
- `wg_myendpoint` must be set on the interface to specify the public IP or hostname where clients will connect
- `wg_listen_port` must be set on the interface to specify the port clients will connect to
- `remote_peer` must be set to `{{ inventory_hostname }}` (the server's hostname) so Ansible can fetch the server's public key for client config generation
- `keepalive` (typically 25 seconds) is highly recommended for clients behind NAT to keep the connection alive. This sets the PersistentKeepalive value in the generated client config.
- `generateclientconfig: true` will create a client configuration file at `{{ openwrt_network_wg_keypath }}/ROADWARRIOR/mylaptop.conf` that can be imported into the client device
- Set `openwrt_network_wg_generateqr: true` (global) to also generate a scannable QR code PNG (`mylaptop.png`) alongside each client config. Requires `qrencode` installed on the Ansible controller. The PNG is regenerated only when the client config changes.
- The MTU defaults to 1420 but can be overridden with the `mtu` property
- If you want additional routes inserted into the client config, use the `routes_to` variable (list)
- `endpoint_host` and `endpoint_port` can be set on the peer to override the interface's `wg_myendpoint` and `wg_listen_port` for client config generation (useful if different clients need different endpoints)

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

#### S2S with one unmanaged endpoint

If only one side of the S2S tunnel is managed by Ansible, set `managekeys: true` on the peer. Ansible will generate a keypair for the unmanaged endpoint. You then need to manually transfer the generated private key (`{peername}_private.key` in `openwrt_network_wg_keypath/{interface}/`) to the unmanaged endpoint's WireGuard configuration. The public key will be automatically placed in the peer config.

```yaml
openwrt_network_wireguardpeers:
  unmanaged-peer.example.com:
    interface: "S2S_tunnel1"
    s2s: true
    remote_peer: "unmanaged-peer.example.com"
    managekeys: true
    setpsk: true
    endpoint_host: "203.0.113.5"
    endpoint_port: 51821
    allowed_ips:
      - "10.10.128.0/20"
```

After running Ansible, copy `~/wireguard-keys/S2S_tunnel1/unmanaged-peer.example.com_private.key` to the unmanaged endpoint.

### Roadwarrior Client (OpenWrt as client)

When the OpenWrt device is a roadwarrior client connecting to an external WireGuard server (not managed by Ansible), set `managekeys: false` on the peer and provide the server's public key manually. The interface's `wg_managekeys` can still be `true` so Ansible generates the OpenWrt device's own keypair.

```yaml
openwrt_network_interfaceshost:
  RWCLIENT:
    proto: "wireguard"
    wg_managekeys: true
    wg_listen_port: 51821
    wg_addresses:
      - "10.10.100.2/32"

openwrt_network_wireguardpeers:
  vpn-server:
    interface: "RWCLIENT"
    managekeys: false
    public_key: "the-servers-public-key"
    endpoint_host: "vpn.example.com"
    endpoint_port: 51821
    allowed_ips:
      - "0.0.0.0/0"
      - "::/0"
    persistent_keepalive: 25
```

> [!WARNING]
> Do NOT set `managekeys: true` on the peer when the OpenWrt device is a roadwarrior client. This would generate a meaningless keypair for the external server and overwrite the `public_key` you provided.

### All scenarios overview

| Scenario | `wg_managekeys` (interface) | `managekeys` (peer) | `remote_peer` | `s2s` | `generateclientconfig` |
|----------|:----:|:----:|:----:|:----:|:----:|
| S2S, both managed | true | true | remote `inventory_hostname` | true | — |
| S2S, one unmanaged | true | true | remote peer name | true | — |
| Roadwarrior server | true | true | `{{ inventory_hostname }}` | — | true |
| Roadwarrior client | true | false | — | — | — |
| Fully manual keys | false | false | — | — | — |

## Kubernetes inbound LB sync

When `openwrt_network_k8s_inbound: true`, the role deploys a hotplug script that
syncs the ISP-delegated IPv6 prefix to a
[CiliumLoadBalancerIPPool](https://docs.cilium.io/en/latest/network/lb-ipam/)
CRD in Kubernetes on each prefix delegation (PD) rotation. This enables pure
end-to-end IPv6 for `Service.type: LoadBalancer` without NAT.

### How it works

1. ISP delegates a dynamic /56 (or /60) via PPPoE prefix delegation
2. OpenWRT's hotplug system fires on `wan6` interface events
3. The script derives a GUA /64 from the PD prefix using a fixed subnet ID
4. The script patches the `CiliumLoadBalancerIPPool` CRD via the Kubernetes API
5. Cilium assigns new GUA IPs to services and emits NDP advertisements
6. The script also updates the static route and nftables rules (notrack + forward)
   on OpenWRT for the new GUA /64

The GUA /64 is **not** assigned to any OpenWRT interface — it exists solely as a
routed /64 for Cilium LB IPAM. The subnet ID must not collide with any existing
VLAN or interface assignment from the PD delegation.

### Variables

| Variable | Default | Description |
|---|---|---|
| `openwrt_network_k8s_inbound` | `false` | Enable/disable k8s inbound LB sync |
| `openwrt_network_k8s_api` | `""` | Kubernetes API server address (e.g. `10.10.112.172:6443`) |
| `openwrt_network_k8s_api_token` | `""` | ServiceAccount bearer token for the K8s API |
| `openwrt_network_k8s_subnetid` | `"20"` | Fixed subnet ID within the PD /56 (hex, e.g. `20` = 4th /64) |
| `openwrt_network_k8s_poolname` | `"junicluster0-lb-pool-gua"` | Name of the CiliumLoadBalancerIPPool CRD to create/update |
| `openwrt_network_k8s_waninterface` | `"wan6"` | OpenWRT interface to watch for PD events |
| `openwrt_network_k8s_landevice` | `"br-lan"` | LAN bridge to route the GUA /64 to |
| `openwrt_network_k8s_tokenfile` | `"/etc/cilium-pd-sync/token"` | Path to the token file on OpenWRT |
| `openwrt_network_k8s_chainname` | `"k8s_lb"` | nftables chain name for firewall rules |
| `openwrt_network_k8s_hotplug_script` | `"/etc/hotplug.d/iface/99-cilium-pd-sync"` | Path to the hotplug script |

### Kubernetes prerequisites

Before enabling this feature, you must create a ServiceAccount in Kubernetes with
permission to manage `CiliumLoadBalancerIPPool` resources. The RBAC is
cluster-scoped because `CiliumLoadBalancerIPPool` is a cluster-scoped resource.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pd-sync
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd-sync-lbpool
rules:
- apiGroups: ["cilium.io"]
  resources: ["ciliumloadbalancerippools"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pd-sync-lbpool
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pd-sync-lbpool
subjects:
- kind: ServiceAccount
  name: pd-sync
  namespace: kube-system
```

Generate a long-lived token for the ServiceAccount:

```bash
kubectl -n kube-system create token pd-sync --duration=87600h
```

Pass the token as `openwrt_network_k8s_api_token` (encrypt it with Ansible Vault).

### Example

```yaml
openwrt_network_k8s_inbound: true
openwrt_network_k8s_api: "10.10.112.172:6443"
openwrt_network_k8s_api_token: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...
openwrt_network_k8s_subnetid: "20"
openwrt_network_k8s_poolname: "junicluster0-lb-pool-gua"
```

### Notes

- The role ensures `curl` is installed on OpenWRT (required for API calls)
- The hotplug script uses a dedicated nftables chain (flushed and repopulated on
  each PD rotation) to avoid rule accumulation
- The script runs once during deployment to set up the pool, route, and firewall
  rules immediately — not just on the next PD rotation
- The GUA /64 subnet ID must not collide with any /64 already assigned to an
  OpenWRT interface. Check with `ip -6 addr show | grep <PD prefix>`
- Cilium must have L2 announcements enabled and IPv6 support for NDP to work
- Token expiry: if the Kubernetes cluster is rebuilt, the ServiceAccount UID
  changes and the token is invalidated. Regenerate and redeploy

### Troubleshooting

#### Force a manual resync

If the pool, route, or firewall rules seem out of sync, clear the state file
and run the hotplug script manually on OpenWRT:

```bash
rm /tmp/cilium-pd-sync-gua-prefix
INTERFACE=wan6 ACTION=ifup /etc/hotplug.d/iface/99-cilium-pd-sync
```

Check the logs for results:

```bash
logread | grep pd-sync
```

#### Verify the GUA pool exists in Kubernetes

Confirm the `CiliumLoadBalancerIPPool` CRD was created/updated with the
current GUA prefix:

```bash
kubectl get ciliumloadbalancerippools
kubectl get ciliumloadbalancerippools <poolname> -o jsonpath='{.spec.blocks}'
```

Verify that services have GUA IPs assigned:

```bash
kubectl get svc -A -o wide | grep LoadBalancer
```

#### Verify the route on OpenWRT

The GUA /64 should be routed to the LAN bridge:

```bash
ip -6 route show | grep <subnet_id>
```

Expected output (prefix varies with PD):

```
2a0a:a547:3315:20::/64 dev br-lan metric 1024 pref medium
```

#### Verify nftables rules on OpenWRT

The dedicated nftables chain should contain notrack and forward rules for
the GUA /64:

```bash
nft list chain inet fw4 k8s_lb
```

Expected output (prefix varies with PD):

```
table inet fw4 {
	chain k8s_lb {
		ip6 daddr 2a0a:a547:3315:20::/64 notrack
		ip6 saddr 2a0a:a547:3315:20::/64 notrack
		iifname "br-lan" oifname "pppoe-wan" ip6 saddr 2a0a:a547:3315:20::/64 accept
		iifname "pppoe-wan" oifname "br-lan" ip6 daddr 2a0a:a547:3315:20::/64 accept
	}
}
```

If the chain is empty or missing, force a manual resync (above).

#### Verify NDP announcements in Kubernetes

Check that Cilium is announcing the GUA LB IPs via NDP on the LAN:

```bash
kubectl -n kube-system get lease | grep l2announce
kubectl -n kube-system exec ds/cilium -- cilium-dbg shell -- db/show l2-announce
```

The `db/show l2-announce` output should list GUA addresses on the node's
physical interface (e.g. `ens3`).

#### Common issues

- **No GUA IP on services**: Check that the GUA pool exists in Kubernetes
  (`kubectl get ciliumloadbalancerippools`) and that the static v4-only pool
  doesn't also contain a v6 block (which would satisfy v6 allocation first).
- **External traffic times out**: Check that the nft forward rules exist in
  both directions (WAN→LAN for inbound, LAN→WAN for return traffic). The
  return path rule is critical — without it, conntrack drops SYN-ACKs.
- **Duplicate nft rules after multiple runs**: The script uses a dedicated
  chain that is flushed and repopulated on each run. If you manually inserted
  rules outside the chain, clean them up with `nft delete rule` by handle.
- **Script doesn't fire on PD rotation**: Verify the hotplug script is at
  `/etc/hotplug.d/iface/` and has mode 0755. Check `logread | grep pd-sync`
  for errors. The script watches for `ifup`/`ifupdate` events on the
  configured WAN interface (default `wan6`).
