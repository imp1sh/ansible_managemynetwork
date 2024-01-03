# ansible_nftables
This role lets you run your nftables firewall without ufw or firewalld or any other wrapper. It's native nftables code. No more iptables.
## setup
* Install role
```
ansible-galaxy collection install imp1sh.ansible_managemynetwork
```
* Assign role to your host
```
---
- hosts: my.firewall.com
  become: true
  roles
    - imp1sh.ansible_managemynetwork.ansible_nftables
```
* Define basic variables
```
nftablesmode: "firewall" [firewall|server]
nftablespolicy: "reject" [reject|drop]
nftableslogging: true [true|false]
```
## Server Mode
You can define rules on a host or group level:
- nftablesopenhost
- nftablesopengroup

For the hosts just put the rules into the host vars, e.g. in host_vars/*hostname*.yml
For definitions on ansible group level ideally put it in something like group_vars/all.yml.
Those are example variable definitions:
```
nftablesopengroup:
  all:
  - dport: "22"
    family: 6
    saddr: "{ {{ ipv6_bla_siteA }}, {{ ipv6_bla_siteB }}, {{ ipv6_bla_siteC }} }"
    daddr: "2a00:fe30:1001:23::2a"
    proto: "tcp"
    comment: "Allow SSH for trusted networks on site A through C"
  icingamaster:
  - dport: "5665"
    family: 46
    inif: "eth0"
    proto: "tcp"
    comment: "Allow Icinga API Port"
```
*all* is the group where everybody is member of, icingmaster is a group where only icinga hosts are member of. The tasks later merge so that every host get rules from every group it is a member of.
Choose family *6* for IPv6 only, *4* for IPv4 only and *46* for dual stack.
inif is optional in case your server has multiple interfaces and you want to restrict the rule for interface-specific incoming traffic.

## Firewall Mode
Let' assume you run it in firewall mode with IPv4 Masquerading / IPv6 routed with eth0 your WAN interface and eth1 LAN.
Define variable as this:
```
nftables_masks:
  - upif: "eth0"
    downif: "eth1"
```
This will enable Masquerading.

Now open up ports like this for incoming packets, inif is optional to define on which incoming interface rule is applied.
```
  - dport: 22
    family: 6
    proto: "tcp"
    saddr: "{{ nfvars['nets']['N6_datacenter_secure']['value'] }}"
    comment: "Allow SSH secure net"
  - dport: "{{ nfvars['ports']['ssh']['value'] }}"
    family: 6
    inif: "eth0"
    proto: "{{ nfvars['ports']['ssh']['proto'] }}"
    saddr: "2a01:4348:aa08:1a03::2"
    comment: "Allow SSH old server ip"
```
It's possible to use globally defined variables as source or destination addresses. That's possible for ports, too. Ideally you'd use some SSOT like Netbox. Here's a very unsophisticated example for using Ansible vars:
```
nfvars:
  nets:
    N6_datacenter_secure:
      value: "2001:a4d0:2264:7a37::/64"
      comment: "Prefix for secure and private network in Datacenter"
  hosts:
    H4_pc_receiption:
      value: "192.168.12.1"
      comment: "This is Richards PC"
  ports:
    ssh:
      value: "22"
      proto: "tcp"
      comment: "SSH service default port"
```
For a firewall it's much more interesting to setup forwardings instead of opening ports on the firewall itself:
```
nftables_forward:
  - inif: "eth0"
    outif: "eth1"
    saddr: "2aa1:4ef0:28d4:7337::/64"
    daddr: "2aa1:470:7e68:1000::/64"
    sport: "23452"
    dport: "22"
    proto: "tcp"
    family: 6
    comment: "Erlaube SSH auf client3 von MGMT"
  - inif: "eth0"
    daddr: "2aa1:0470:7e68:1000::/64"
    saddr: "2aa1:4ef0:28d4:1b::/64"
    dport: "22"
    proto: "tcp"
    family: 6
    outif: "eth1"
    comment: "Erlaube SSH auf client3 von secure"
```
Opening ICMP is not yet possible, working on it.
For dnat use something like this:
```
nftables_dnat:
  - dport: 801
    ip: "172.16.33.16"
    proto: "tcp"
    inif: "eth0"
    outif: "eth1"
    comment: "Forward Port 801 to host 16"
  - dport: 4431
    ip: "172.16.33.16"
    proto: "udp"
    inif: "eth0"
    outif: "eth1"
    comment: "Forward Port 4431 to host 16"
```
Redirecting ports not yet possible.
