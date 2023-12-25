# Ansible Managemynetwork Collection (MMN)

This is a collection that is flexible and extensive at the same time. It aims to handle all the tasks that one would want in a complex network environment. Each role only cares about its specific task. So installing packages for example is exclusively done in the packages role and not within others.

The main Focus will be Debian Linux. I had been using Alpine and FreeBSD for a long time but the focus will be a more homogenous environment based on mainly Debian. Yet all roles are build so they can be expanded to more OSes very easily. Feel free to make a pull request.

That is why this collection will try to support all of those Operating Systems with all of the included roles:
- Debian Linux (main focus)
- FreeBSD (best effort)
- Ubuntu Linux (best effort)
- ~~Manjaro/Arch Linux~~ (rarely supported across the roles)
- ~~Alpine Linux~~ (may work, but basically deprecated)
- ~~RedHat and Clones~~ (may work, but basically deprecated)

Generally speaking this collection aims to achieve a seperation of logical elements being only in the role. This way all you have to do is call the role. Manual adjustmens to the playbook are very rare. All you do is set your variables and then run the role / collection.


> This Collection is quite old. It grew over time and contains LOTS of different roles. Only consider the documented roles to be in a *ready for production* state.
> All other roles will be removed or lifted to the same quality standard in the future.
{.is-warning}

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

