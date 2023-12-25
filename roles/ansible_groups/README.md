# imp1sh.ansible_managemynetwork.ansible_groups

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_groups)

This role manages groups for hosts.
It currently supports these Operating Systems:
- Debian
- Ubuntu (best effort)
- FreeBSD (best effort)
- ~~Alpine~~ (probably works but no longer supported)
- ~~Arch~~ (probably works but no longer supported)
- ~~Manjaro~~ (probably works but no longer supported)

Groups will be defined within the dict variable *system_groups* with the attributes described in the [Ansible Group module docs](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/group_module.html).


Since you don't want to define your groups for every host individually, you need to place your variable somewhere every host has access to it. In this example the `system_groups` variable will be defined in the scope of an Ansible group called *tags_allhosts*.

./group_vars/tags_allhosts.yaml

Here is an example:
```yaml
system_groups:
  ansiblesudo:
    state: "present"
    gid: 9000
  sudo:
    state: "present"
    gid: 9001
```

## Host association
Wheter or not a group is installed or uninstalled on a host is decided by a special variable that associates posix groups with either hosts or ansible groups. To associate a posix group to a host use `system_groups_create_on_hosts` and to associate with a distinct ansible group use `system_groups_create_on_hostgroups`.

Example:
```yaml
system_groups_create_on_hostgroups:
  ansiblesudo:
    - "tags_allhosts"
  sudo:
    - "tags_allhosts"
system_groups_create_on_hosts:
  ansiblesudo:
  - "host1.example.com"
  - "hostB.example.com"
  sudo:
  - "supercomputer1.example.com"
```

## Remove groups
Make sure the group is associated with the hosts or hostgroups you want it to uninstall from. Set the `state` attribute to *absent*. Run your playbook.
