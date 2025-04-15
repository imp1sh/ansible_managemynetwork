# Ansible Managemynetwork Collection (MMN)

This is a collection that is flexible and extensive at the same time. It aims to handle all the tasks that one would want in a complex network environment (Manage My Network).
There are some paradigms every role in this collection shall conform with:
- A role shall only care about its own specific field / domain.
  Installing packages for example is exclusively done in the packages role and not within others. By 2025 not all rules comply with those requirements, yet.
- there's always the need to define vars on a host level and/or group level in Ansible. Thus the roles in this very collection shall also abide to having a dedicated host var (host suffix in the var name) and a dedicated group var (group suffix in the var name). This requirement though is soft and up to the maintainer of the role / collection.
- The main Focus will be **Debian Linux** and **OpenWrt**. It once suppoirted Alpine and FreeBSD for a longer amount of time.
- New roles shall always be created in a fashion that they will be more easily adoptable for other OSes.
- OpenWrt specific roles will inherently all support the [ansible_openwrtimagebuilder](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtimagebuilder/README.md) role. This can only be verified to be true when you use this role to build images successfully with the  role.
- OpenWrt specific roles stay specific to OpenWrt unless there are common tasks like user management, zabbix agent, package installation and alike, that are not inherently different on OpenWrt in contrast to Debian. When possible and when meaningful roles will have support for Debian and OpenWrt at the same time.
- This collection aims to achieve a seperation of programmatical elements being only in the role. This way all you have to do is call the role. Tasks withing playbooks should be very rare. All you do is set your variables and then run the role / collection.
- Feel free not to procrastinate but to participate. Pull requests, issues and discussions are very welcome.

## Maintenance Status

> Actively maintained

Each role has a specific purpose. You can use them seperately to control specific application, services or on OpenWrt: UCI sections. It is desirable though to control the system as a whole with Ansible. If you do, neither make changes manually by command line nor via the webinterface on the target host directly. Changes will otherwise be overwritten by Ansible.
If my collection lacks a feature or you find a bug, open an [issue in the git bugtracker](https://github.com/imp1sh/ansible_managemynetwork/issues).

## The big OpenWrt Merge

OpenWrt roles were merged from [imp1sh.ansible_openwrt](https://github.com/imp1sh/ansible_openwrt) into imp1sh.ansible_managemynetwork in December 2023.

This collection will offer support for:
- **Debian Linux** (main focus)
- **OpenWrt** (main focus)
- FreeBSD (only by popular request)
- Ubuntu Linux (only by popular request)
- ~~Manjaro/Arch Linux~~ (rarely supported across the roles)
- ~~Alpine Linux~~ (may work as it had been used for years in some roles; basically deprecated)
- ~~RedHat and Clones~~ (may work, but basically deprecated, definitively no support any longer)

Some roles support Debian and OpenWrt at the same time.



> This Collection grew over time and contains LOTS of different roles. Only consider the documented roles to be in a *ready for production* state.
> All other roles will be removed or lifted to the same quality standard in the future.
> Until that point is not reached released version will stay below 1.x.

## General roles

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
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_podman](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_podman/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_qemuagent](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_qemuagent/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_restic](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_restic/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_sshkeys](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_sshkeys/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_sudo](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_sudo/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_users](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_users/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_zabbixagent](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_zabbixagent)

## OpenWrt specific roles
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtacme](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtacme/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtbabeld](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtbabeld/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtdhcp](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtdhcp/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtdropbear](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtdropbear/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtfirewall](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtfirewall/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtfstab](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtfstab/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtimagebuilder](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtimagebuilder/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtnetwork](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtnetwork/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtpackages](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtpackages/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtpodman](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtpodman/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtprometheus_node_exporter_lua](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtprometheus_node_exporter_lua/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtservices](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtservices/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtsqm](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtsqm/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtsystem](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtsystem/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrttinyproxy](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrttinyproxy/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtuhttpd](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtuhttpd/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtusteer](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtusteer/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtwireguard](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtwireguard/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtwireless](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtwireless/README.md)


The roles starting with *ansible_openwrt\** are OpenWrt specific. The goal is to be able to manage every aspect of OpenWrt centrally with Ansible.

### Advantages of imp1sh OpenWrt roles

The roles contained in this collection are pretty powerful. There are even some options that are not accessible through the LUCI Webinterface. In contrast to using LUCI, multiple OpenWrt devices can be managed with Ansible centrally. With it you are able to deploy settings individually, on a group basis or even for every device in your environment.

It can be viewed as an alternate solution to [OpenWisp](https://openwisp.org/). Yet it is more flexible because it's based upon the super powerful Ansible software.
It is targeted towards Service Providers, Hosters or Cloud Providers but it's also well suited for home environments. With it you can manage plenty of Access Points / Firewalls with low effort. Using it will help you dramatically in order to make your device configurations consistent.

Use Ansible properties to your needs, e.g. defining variables once and use them often. This simplifies management fundamentally.
At the same time you can access the expandibility and flexibility of OpenWrt and its packages.

### Hardware requirements OpenWrt device

The openwrt roles in this collection us **python** which is not installed on stock OpenWrt. You will need quite a lot of storage so you can install it. Those are the minimum device properties.

### Minimum requirements
* 128 MB Storage
* OpenWrt 22.01 or higher
* Python3 installed on the target device
* 128+ MB,for Restic 512+ MB RAM

### Recommendation

Depending on your needs the requirements might be higher. Depending on the additional packages you need you will need more disk space. Generally speaking I would recommand a device with:
* 256+ MB Storage
* OpenWrt 24.10
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

### Development integration

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

> The collection expects to have an Ansible group containing all hosts. In the docs we typically use the name **tags_allhosts** defined.
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

Example for defining a rule for one specific host:

```
openwrt_firewall_ruleshost:
  "icmp wan to dmz":
    src: "WAN"
    dest: "DMZ"
    proto: "icmp"
    target: "ACCEPT"
```

In contrast to the common ansible convention of defning group variable values within the actual group scope we need a more global group containing all hosts like **tags_allhosts**. The assocition to the group(s) is done via a dict item representing the actual group name. In this example the groups are *openwrthosts* and *openwrtaccesspoints*.

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

| Role | Varible Prefix |
| - | - |
|imp1sh.ansible_managemynetwork.ansible_openwrt**system** |  `openwrt_system_*` |
|imp1sh.ansible_managemynetwork.ansible_openwrt**dropbear** | `openwrt_dropbear_*` |
|imp1sh.ansible_managemynetwork.ansible_openwrt**services** | `openwrt_services_*` |
|imp1sh.ansible_managemynetwork.ansible_openwrt**network**  | `openwrt_network_*` |
|imp1sh.ansible_managemynetwork.ansible_openwrt**firewall** | `openwrt_firewall_*` |
|imp1sh.ansible_managemynetwork.ansible_openwrt**dhcp** | `openwrt_dhcp_*` |
|imp1sh.ansible_managemynetwork.ansible_openwrt**packages** | `òpenwrt_packages_*` |
|imp1sh.ansible_managemynetwork.ansible_**restic** | `openwrt_restic_*` |
|imp1sh.ansible_managemynetwork.ansible_openwrt**dhcp** |`openwrt_dhcp_*` |
|imp1sh.ansible_managemynetwork.ansible_openwrt**acme** | `openwrt_acme_*` |

## Development / Contribution Conventions
- Ansible task names start with `MMN <<rolename>> - Text that describes the task brief but sufficient`
- Ansible task descriptions start with Capital letter
- Maintain meta information for role
- Maintain README.md for every role
- Seperation of Duty. Every role works in their scope and in their scope only. Diverge only if no other way possible
- Test your stuff. Don't only look at main case but at least most pressing corner cases
- Use consistent variable names and put them in roles namespace like start the var name with e.g. `psql_` for postgresql role.
- Only be opinionated when your opinion is strong and validated. Don't do opinionated due to lazyness
- Make your role so that it can esily be fitted for additional OSes. Best practice is to have OS dependant vars and load them automatically. This way you can adjust to different package or folder names more easily.
