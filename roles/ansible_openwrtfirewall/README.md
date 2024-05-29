# imp1sh.ansible_managemynetwork.ansible_openwrtfirewall

This role manages

-   Global Firewall rules
-   Firewall zones
-   Zone Forwardings
-   Traffic Rules
-   Port Forwards (SNAT / DNAT)

## Global Variables
For a full list of available options, see [OpenWrt Wiki Firewall](https://openwrt.org/docs/guide-user/firewall/firewall_configuration#defaults)

This is just an excerpt:
| Ansible Variable Name | OpenWrt Flag Name | Default Value |
| --- | --- | --- |
| `openwrt_firewall_default_synflood_protect` | synflood\_protect | 1   |
| `openwrt_firewall_default_flow_offloading` | flow\_offloading | 0   |
| `openwrt_firewall_default_flow_offloading_hw` | flow\_offloading\_hw | 0   |
| `openwrt_firewall_default_forward` | forward | REJECT |
| `openwrt_firewall_default_input` | input | ACCEPT |
| `openwrt_firewall_default_output` | output | ACCEPT |
| `openwrt_firewall_default_drop_invalid` | drop\_invalid | -   |
| `openwrt_firewall_default_synflood_rate` | synflood\_rate | -   |
| `openwrt_firewall_default_synflood_burst` | synflood\_burst | -   |
| `openwrt_firewall_default_tcp_syncookies` | tcp\_syncookies | -   |
| `openwrt_firewall_default_tcp_ecn` | tcp\_ecn | -   |
| `openwrt_firewall_default_tcp_window_scaling` | tcp\_window\_scaling | -   |
| `openwrt_firewall_default_accept_redirects` | accept\_redirects | -   |
| `openwrt_firewall_default_accept_source_route` | accept\_source\_route | -   |
| `openwrt_firewall_default_custom_chains` | custom\_chains | -   |
| `openwrt_firewall_default_tcp_reject_code` | tcp\_reject\_code | \-  |
| `openwrt_firewall_default_any_reject_code` | any\_reject\_code | \-  |

## Zones
We use zones names written in capital letters, e.g. *WAN*. Ansible variable names do not make use of that convention.
Zones are the core of firewall operations in OpenWrt. In the following cases:
- No zones exist
- Zones exist, but no interface is attached to them
The following rules apply:
- global directives for `Input` `Output` and `Forward` apply
- this shall never happen in a productive environment

Thus you need to attach an interface to a firewall zone so that the firewall can make decisions about the various packets.
For a more detailed documentation look at the official [firewall docs of OpenWrt](https://openwrt.org/docs/guide-user/firewall/firewall_configuration).

### Predefined Firewall Zones

In contrast to a factory OpenWrt firmware this role ships with more default zones.

| Description | Default Zonename | Default masq | Default logging |
| --- | --- | --- | --- |
| Internet Uplink | **WAN** |  1   | 1   |
| Connecting to neighbours | **NEIGHBOURS** |  0   | 1   |
| Guests, e.g. Guest Wifi| **GUESTS** | 0   | 1   | 
| your common LAN clienst | **LAN** | 0   | 1   | 
| Services / Server | **DMZ** | 0   | 1   
| Management, z.B. IPMI, switches, Access Points | **MGMT** |  0   | 1   | 

Those are pre defined zones coming with a defaultset of rules. You **NEED TO** assign an interface to them so that they are being utilized. Otherwise they won't be used, **AT ALL**.

There are three different variables to manage zones. All of them are being defined as a dict variable.

* openwrt_firewall_zonesgroup
* openwrt_firewall_zoneshost
* openwrt_firewall_zonesdefault


This is an excerpt of the default zones
```yaml
openwrt_firewall_zonesdefault:
  WAN:
    forward: "REJECT"
    input: "REJECT"
    output: "ACCEPT"
    log: "1"
    masq: "1"
    mtu_fix: "1"
```

In order to modify the default zones some manual work is necessary. At first you need to define your very own variable in the same format and set your specifics. This is an example of how to assign an interface to a default zone.

1)  Define a variable at the scope of a host or group in Ansible:
```yaml
openwrt_firewall_zones_mysite:
  MGMT:
    interfaces:
      - "MGMT"
      - "MGMT6"
    input: "ACCEPT"
```
Additionally you need to define your own task within your playbook file.

```yaml
- hosts: platforms_openwrt
  pre_tasks:
    - name: combine default zones with manual settings
      set_fact:
        openwrt_firewall_zonesdefault: "{{ openwrt_firewall_zonesdefault | combine(openwrt_firewall_zones_mysite, recursive=true) }}"
      when: openwrt_firewall_zones_mysite is defined
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_openwrtfirewall
```

This will merge `openwrt_firewall_zonesdefault` and `openwrt_firewall_zones_mysite`
See also Ansible docs for [combining dicts](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html#combining-hashes-dictionaries)

To specify interfaces the logical names from */etc/network/interfaces* are being used. In Ansible they are being defined in [ansible\_openwrtnetwork](/en/junicast/docs/AnsibleOpenWrtCollection/roleNetwork) via the variable`openwrt_network_interfaces` , e.g.:
```yaml
openwrt_network_interfaces:
  wan:
    device: "eth1"
    proto: "dhcp"
  wan6:
    device: "@wan"
    proto: "dhcpv6"
```

### Deactivate single Firewall zone
If you need to disable single zones you can do that by setting the `disabled` flag to true. For example
```yaml
openwrt_firewall_zoneshost:
  MYZONE:
    ...
    disabled: true
    ...
```
This might be helpful if you temporarily would like to disable a zone but not remove it from the Ansible configuration.

### Disable all Default Zones
The default zones are quite extensive. If they do not fit your environment you might want to define all your zones by yourself. You can deactivate the default zones by setting:
```yaml
openwrt_firewall_setdefaultzones: false
```
Don't forget to define your own zones. An OpenWrt Firewall without zones cannot be fully functional. The default rules may also be not applied. The Ansible Collection checks if zones exist when it tries to apply rules. If a rule is associated with a non existant zone, the rule won't be applied at all. This may lead to default rules not being applied and can cause problems for example with DHCP requests not being answered.

### Your own Firewall Zones

Apart from the predefined zones you can define your own. The names of your zones may not interfere with the default zones, if applied.

You can either define zones for a host or for a group of hosts. This is an example for a zone named PRINTERS with the interface named `printers` to be set on a single host.
```yaml
openwrt_firewall_zoneshost:
  PRINTERS:
    forward: “REJECT”
    input: “REJECT”
    output: “ACCEPT”
    log: “0”
    interfaces:
      - “printers”
```
If you want to define zones for multiple hosts you can do that in the `allhosts` scope, e.g. `./group_vars/allhosts.yml`. This is an example that will be applied to allhosts member of the group *group1*.

```yaml
openwrt_firewall_zonesgroup:  
  group1: 
    SPEZIAL1:
      forward: "ACCEPT"  
      input: "ACCEPT"  
      output: "ACCEPT  
      log: “0”  
      interfaces:  
        - "spezial1"  
    DMZ2:  
      forward: "ACCEPT"  
      input: "ACCEPT"  
      output: "ACCEPT"  
      log: “0”  
    GUESTS2:
      forward: "REJECT"  
      input: "REJECT"  
      output: "ACCEPT"  
      log: “0”  
    FRITZ:
      forward: "REJECT"  
      input: "REJECT"  
      output: "ACCEPT"  
      log: “1”  
      masq: 1  
      mtu_fix: 1  
      interfaces:  
        - "fritz1"  
        - "fritz2"
```

## Forwardings
Forwardings define how packets between zones are handled. So if there is a forwarding rule from `LAN` to `DMZ` all hosts in `LAN` can fully access hosts in `DMZ`.
See also: [OpenWrt Firewall docs](https://openwrt.org/docs/guide-user/firewall/firewall_configuration#forwardings)
A forwarding has to have a `SRC` as well as `DEST` attribute. 

> Forwardings are only being applied when the `SRC` and `DEST` zones both exist.
{.is-warning}

### Predefined Forwardings
There is a default forwarding, allwing `LAN` to `WAN` access. Other forwardings you need to define yourself.

### Forwardings for a Single Host
Define in Ansible on a host scope like this:

```yaml
openwrt_firewall_forwardingshost:  
 - src: “MGMT”  
   dest: “WAN”
```
### Forwardings for a Group of Hosts:

Define in the `allhosts` scope, e.g. in `group_vars/allhosts.yml`
```yaml
openwrt_firewall_forwardingsgroup:  
  group1:  
  - src: “MYZONE1”  
    dest: “WAN”  
  group2:  
  - src: “MYZONE2”  
    dest: “WAN”
```

## Firewall Rules
Rules define how packets are being handled. Possible actions are *DROP*, *REJECT* or *ACCEPT*.
In the `src` and/or `dest` attribute there may be a wildcard, i.e. `*`. This will match every zone.
If you skip the `dest` attribute it will become an `Input` Rule, meaning the traffc's destination address is the firewalls IP itself.

> Rules are only being applied, if the referenced zone(s) actually exists.
{.is-warning}

Those are mandatory attributes for a rule:
* *target*
* *src*

All other attributes are optional.


### Predefined Rules
There are some predefined rules that are meant for the predefined zones. In contrast to stock OpenWrt there are some minor changes. In accordance to [RFC4890](https://datatracker.ietf.org/doc/html/rfc4890) several ICMPv6 packates are being passed. Additionally there are some more predefined rules as there are more predefined zones.
In the [github repo](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtfirewall/defaults/main.yml) you can inspect those default rules, see variable:  `openwrt_firewall_rulesdefault`.

### Rules for a Single Host:
Example configuration for a single host two rules.
```yaml
openwrt_firewall_ruleshost:
  "zabbix1_anywhere":
    family: "ipv6"
    src: "WAN"
    src_ip:
      - "{{ hostvars['zabbix1.example.com']['netinterfaces']['ens18']['ip6'] | ipaddr('address') }}"
    dest: "*"
    proto:
      - "tcp"
    dest_port: "10050"
    target: "ACCEPT"
  "admin_accept wan":
    family: "ipv6"
    src: "WAN"
    target: "ACCEPT"
    proto:
      - "all"
    src_ip:
      - "2001:1234:4321::/48"
      - "2a01:affe::/32"
  "SECURE to MGMT ssh":
    family: "ipv6"
    src: "SECURE"
    dest: "MGMT"
    target: "ACCEPT"
    proto:
      - "tcp"
    dest_port: "22"
```
For a full list of attributes see [OpenWrt Firewall docs](https://openwrt.org/docs/guide-user/firewall/firewall_configuration#rules).

> Be careuful about firewall rules. If you mistype or forget e.g. a `dest_port` directive the rule will get installed, without a restriction to a port. This might open up your firewall much wider than you might want to.
{.is-warning}

### Rules for a Group of Hosts
As in most sections there is also the possibility to defines rules on a Ansible group scope. Here's an example, defined in `./group_vars/allhosts.yml`:
```yaml
openwrt_firewall_rulesgroup:
  openwrtaccesspoints:
    "Admin Access":
      src: "MGMT"
      proto: "all"
      target: "ACCEPT"
  openwrtrouter:
    "LAN to MGMT HTTP Admins":
      src: "LAN"
      dest: "MGMT"
      proto: "tcp"
      dest_port: "80"
      src_ip:
        - "1.2.3.5"
        - "2a01:4:6::1"
     target: "ACCEPT"
```

## Port Forwardings / Redirections
Of course forwardings can be setup via this role. This is not about general masquerading. This is being setup in the zones section of this role with the attributes `masq: 1` and `mtu_fix: 1`. 
For specific SNAT / DNAT rules those can be setup via rules. There are two va`riables available to define rules, i.e.  *openwrt_firewall_redirectsgroup* and *openwrt_firewall_redirectshost*. A full list of available attributes for those rules can be found in the [Openwrt documentation for redirects](https://openwrt.org/docs/guide-user/firewall/firewall_configuration#redirects).

### DNAT / Port Forward
```yaml
openwrt_firewall_redirectshost:
  "jabber 5222 chathost1":
    proto:
      - "tcp"
    src: "WAN"
    dest: "MEINS"
    src_dip: "5.123.321.82"
    dest_ip: "10.10.102.19"
    src_dport: 5222
    target: "DNAT"
```

If you want a DNAT rule, `src`is mandatory.
If you define a SNAT rule, `src_dip`and `dest`are mandatory.
