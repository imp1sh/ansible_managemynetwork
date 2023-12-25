# Ansible Managemynetwork Collection (MMN)

This is a collection that is flexible and extensive at the same time. It aims to handle all the tasks that one would want in a complex network environment. Each role only cares about its specific task. So installing packages for example is exclusively done in the packages role and not within others.

The main Focus will be Debian Linux and OpenWrt. I had been using Alpine and FreeBSD for a long time but the focus will be a more homogenous environment based on mainly Debian. Yet all roles are build so they can be expanded to more OSes very easily. Feel free to make a pull request.

OpenWrt roles were merged from imp1sh.ansible_openwrt into imp1sh.ansible_managemynetwork in December 2023.

That is why this collection will try to support all of those Operating Systems with all of the included roles:
- Debian Linux (main focus)
- OpenWrt (main focus)
- FreeBSD (best effort)
- Ubuntu Linux (best effort)
- ~~Manjaro/Arch Linux~~ (rarely supported across the roles)
- ~~Alpine Linux~~ (may work, but basically deprecated)
- ~~RedHat and Clones~~ (may work, but basically deprecated)

Generally speaking this collection aims to achieve a seperation of logical elements being only in the role. This way all you have to do is call the role. Manual adjustmens to the playbook are very rare. All you do is set your variables and then run the role / collection.


> This Collection is quite old. It grew over time and contains LOTS of different roles. Only consider the documented roles to be in a *ready for production* state.
> All other roles will be removed or lifted to the same quality standard in the future.


  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_borgmatic](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_borgmatic/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_chrony](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_chrony/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_dehydrated](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_dehydrated/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_groups](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_groups/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_hostname](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_hostname/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_netbox2yaml](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_netbox2yaml/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_nsupdate_bash](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_nsupdate_bash/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_ohmyzsh](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_ohmyzsh/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_packages](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_packages/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_qemuagent](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_qemuagent/README.md)
 - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_sshkeys](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_sshkeys/README.md)
 - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_sudo](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_sudo/README.md)
 - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_users](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_users/README.md)

OpenWrt specific
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtacme](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtacme/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtbabeld](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtbabeld/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtdhcp](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtdhcp/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtdropbear](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtdropbear/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtfirewall](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtfirewall/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtimagebuilder](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtimagebuilder/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtnetwork](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtnetwork/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtpackages](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtpackages/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtpodman](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtpodman/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtprometheus_node_exporter_lua](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtprometheus_node_exporter_lue/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtrestic](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtrestic/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtservices](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtservices/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtsqm](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtsqm/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtsystem](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtsystem/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrttinyproxy](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrttinyproxy/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtuhttpd](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtuhttpd/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtwireguard](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtwireguard/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtwireless](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtwireless/README.md)
  - [:leftwards_arrow_with_hook: imp1sh.ansible_managemynetwork.ansible_openwrtzabbix](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtzabbix/README.md)
