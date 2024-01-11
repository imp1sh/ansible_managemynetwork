# Ansible Managemynetwork Collection (MMN)

This is a collection that is flexible and extensive at the same time. It aims to handle all the tasks that one would want in a complex network environment. Each role only cares about its specific task. So installing packages for example is exclusively done in the packages role and not within others. I try to follow this paradigm throughout all rules, even when I'm not completely there, yet.
Another concept I try to follow is that there's always the need to define on a host level and/or on a group level in Ansible. When the role is done right (and currently that's not every role, yet) there are specific variable for defining things on a host or on a group level.

The main Focus will be Debian Linux and OpenWrt. I had been using Alpine and FreeBSD for a long time but the focus will be a more homogenous environment based on mainly Debian. Yet all roles are build so they can be expanded to more OSes very easily. Feel free to make a pull request.

OpenWrt roles were merged from imp1sh.ansible_openwrt into imp1sh.ansible_managemynetwork in December 2023. In the course of the following year of 2024 I will partly merge them further, like zabbix agent. This will soon be merged into one role that can handle normal Linuxes as well as OpenWrt instead of having two seperate roles for that. 

This collection will try to support all of those Operating Systems:
- **Debian Linux** (main focus)
- **OpenWrt** (main focus)
- FreeBSD (best effort)
- Ubuntu Linux (best effort)
- ~~Manjaro/Arch Linux~~ (rarely supported across the roles)
- ~~Alpine Linux~~ (may work, but basically deprecated)
- ~~RedHat and Clones~~ (may work, but basically deprecated)

Some roles are and will stay OpenWrt only, like ansible_openwrtfirewall. Others will be united further in the future.

Generally speaking this collection aims to achieve a seperation of logical elements being only in the role. This way all you have to do is call the role. Manual adjustmens to the playbook are very rare. All you do is set your variables and then run the role / collection.


> This Collection is quite old. It grew over time and contains LOTS of different roles. Only consider the documented roles to be in a *ready for production* state.
> All other roles will be removed or lifted to the same quality standard in the future.


  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_borgmatic](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_borgmatic/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_chrony](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_chrony/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_dehydrated](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_dehydrated/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_groups](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_groups/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_hostname](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_hostname/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_motd](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_motd/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_netbox2yaml](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_netbox2yaml/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_nsupdate_bash](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_nsupdate_bash/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_ohmyzsh](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_ohmyzsh/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_packages](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_packages/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_qemuagent](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_qemuagent/README.md)
 - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_sshkeys](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_sshkeys/README.md)
 - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_sudo](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_sudo/README.md)
 - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_users](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_users/README.md)

# OpenWrt specific

The roles starting with *ansible_openwrt\** are OpenWrt specific.The goal is to be able to manage every aspect of OpenWrt centrally with Ansible.


## Advantages of imp1sh Ansible Collection

The roles contained in this collection are pretty powerful. There are even some options that are not accessible through the LUCI Webinterface. In contrast to using LUCI multiple OpenWrt devices can be managed with Ansible centrally. With it you are able to deploy settings individually, on a group basis or even for every device in your environment.

It can be viewed as an alternate solution to [OpenWisp](https://openwisp.org/). Yet it is more flexible because it's based upon the super powerful Ansible software.
It is targeted towards Service Providers, Hosters or Cloud Providers. With it you can manage plenty of Access Points / Firewalls with low effort. It is also suitable for smaller and medium sized environments in order to make sure every node is configured consistently.

Use Ansible properties to your needs, e.g. defining variables once and use them often. This simplifies management fundamentally. Even the big players like pfSense do not offer a central management for multiple firewalls.
At the same time you can access the expandibility and flexibility of OpenWrt and its packages.

## Hardware requirements OpenWrt device

The openwrt roles in this collection us **python** which is not installed on stock OpenWrt. You will need quite a lot of storage so you can install it. Those are the minimum device properties.

### Minimum requirements
* 128 MB Storage
* OpenWrt 22.01 or higher
* Python3 installed on the target device
* 128+ MB,for Restic 512+ MB RAM

### Recommendation

Depending on your needs the requirements might be higher. Depending on the additional packages you need you will need more disk space. Generally speaking I would recommand a device with:
* 256+ MB Storage
* OpenWrt 22.03
* 512+ MB RAM

## Installation

If you're not using Ansible already please take a look at:
* [Ansible Quickstart](https://docs.ansible.com/ansible/latest/user_guide/quickstart.html) 
* [Ansible Getting Started](https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html).
You need a system acting as Ansible controller in order to deploy the target nodes. You can not use OpenWrt itself to act as the controller. The target nodes must be reachable via network and the Ansible Controller's SSH public key needs to be installed (System - Administration - SSH-Keys). Try to ssh into the node from the controller.
```
ssh root@<<ip or hostname of the openwrt systems>>
```
The login must be successful without errors and without asking for a password.

To install the collection you can use the `ansible-galaxy` command or you clone the git repo.
The preferred method is to install via

```
ansible-galaxy collection install imp1sh.ansible_managemynetwork
```

If you prefer to use the development version use: 

To install into the local working directory:
```
cd << Ansible working directory>>
ansible-galaxy collection install git+https://github.com/imp1sh/ansible_nftwallcollection.git -p .collections
```

This will install the collection into the default path:
```
cd <<Ansible working directory>>
ansible-galaxy collection install git+https://github.com/imp1sh/ansible_nftwallcollection.git
```

> The collection expects to have an Ansible group named **allhosts** defined. All nodes need to be part of the group.
{.is-warning}

## Using the roles

Use the roles in a playbook by referencing the roles you need, for example:
```
---
- hosts: manacdev
  roles:
  - imp1sh.ansible_managemynetwork.ansible_openwrtsystem
  - imp1sh.ansible_managemynetwork.ansible_openwrtdropbear
  - imp1sh.ansible_managemynetwork.ansible_openwrtservices
  - imp1sh.ansible_managemynetwork.ansible_openwrtnetwork
  - imp1sh.ansible_managemynetwork.ansible_openwrtfirewall
  - imp1sh.ansible_managemynetwork.ansible_openwrtdhcp
 ```


## Variables

You can define variables in Ansible on a host or on a group basis. The variable type corresponds to the UCI datatype. If it is a list in UCI, it is a list in Ansible.
Depending on what level you choose the variable names may differ, depending if you choose to define on host or group basis.

There need to a group named *allhosts*. Within its scope you defined several variables.

Example for defining a rule for one specific host:
```
openwrt_firewall_ruleshost:
  "icmp wan to dmz":
    src: "WAN"
    dest: "DMZ"
    proto: "icmp"
    target: "ACCEPT"
```

In contrast you can define packages to be installed on a group basis within  *./group_vars/allhosts.yml*. This will deploy the packages to all hosts member of the group openwrthosts.
```
openwrt_packagesinstallgroup:
  openwrthosts:
    - "acme"
    - "acme-dnsapi"
    - "coreutils"
    - "flashrom"
    - "htop"
    - "luci-app-acme"
    - "luci-app-statistics"
    - "luci-app-vnstat2"
    - "nmap-full"
    - "python3"
    - "screen"
    - "tcpdump"
    - "vim-fuller"
    - "vnstat2"
    - "vnstati2"
    - "zabbix-agentd"
    - "zabbix-extra-wifi"
  openwrtaccesspoints:
    - "ath10k-board-qca988x"
    - "ath10k-firmware-qca988x"
    - "ath9k-htc-firmware"
    - "kmod-ath10k"
    - "kmod-ath9k"
    - "kmod-ath9k-common"

```

## Naming conventions for variables

Variable names are constructed by using the role name which is at the same time the uci section name. The wildcard part (\*) is the subsection within uci for example:
`openwrt_system_hostname`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**system**
Variables: `openwrt_system_*`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**dropbear**
Variables: `openwrt_dropbear_*`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**services**
Variables: `openwrt_services_*`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**network**
Variables: `openwrt_network_*`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**firewall**
Variables: `openwrt_firewall_*`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**dhcp**
Variables: `openwrt_dhcp_*`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**packages**
Variables: `òpenwrt_packages_*`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**restic**
Variables: `openwrt_restic_*`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**dhcp**
Variables: `openwrt_dhcp_*`

Role: imp1sh.ansible_managemynetwork.ansible_openwrt**acme**
Variables: `openwrt_acme_*`

## Roles of this collection

Each role has a specific purpose. You can use them seperately to control specific uci sections. It is desirably though to control the system as a whole with Ansible. If you do, neither make changes manually by command line nor via the webinterface. Changes will be overwritten by Ansible.

If my collection lacks a feature or you find a bug, open an [issue](https://github.com/imp1sh/ansible_managemynetwork/issues) in the git bugtracker.

  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtacme](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtacme/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtbabeld](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtbabeld/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtdhcp](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtdhcp/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtdropbear](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtdropbear/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtfirewall](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtfirewall/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtimagebuilder](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtimagebuilder/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtnetwork](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtnetwork/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtpackages](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtpackages/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtpodman](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtpodman/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtprometheus_node_exporter_lua](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtprometheus_node_exporter_lua/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtrestic](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtrestic/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtservices](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtservices/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtsqm](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtsqm/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtsystem](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtsystem/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrttinyproxy](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrttinyproxy/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtuhttpd](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtuhttpd/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtwireguard](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtwireguard/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtwireless](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtwireless/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtzabbix](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtzabbix/README.md)
