# imp1sh.ansible_managemynetwork.ansible_groups

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_groups)

This role manages POSIX groups for hosts.
It currently supports those Operating Systems:
- Debian
- Ubuntu
- Alpine
- Archlinux
- CentOS / RHEL / Rocky / Alma (EL)
- Fedora
- FreeBSD
- OpenWrt

## OpenWrt specific
When using this with OpenWrt it will install those packages so ansible.builtin.group can do its job:
- shadow-groupadd
- shadow-groupdel
- shadow-groupmod

This role is also compatible with [ansible_openwrtimagebuilder](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtimagebuilder/README.md). It works by deploying an init script into `/etc/uci-defaults/` on the built image that runs once at first boot, creating or updating the group.

If you do `import_playbook` on the groups role but you only want it to run on OpenWrt, use:
```yaml
- name: MMN groups
  import_playbook: groups.yml
  when: ansible_distribution == 'OpenWrt'
```
while the groups playbook looking like this:
```yaml
---
- name: Handling groups in Linux, Unix
  hosts: all
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_groups
```

## Role toggles

| Variable | Default | Description |
|----------|---------|-------------|
| `system_groups` | _(unset)_ | Dictionary of groups to manage. The role does nothing if this is unset. |
| `system_groups_runimagebuilder` | `false` | Set to `true` to run in imagebuilder mode (deploys uci-defaults init scripts to the build host instead of managing groups live). |
| `system_groups_additional_packages` | _(OpenWrt only)_ | List of extra packages to install via the `ansible_packages` role. Defined per-OS in `vars/`; on OpenWrt this is `shadow-groupadd`, `shadow-groupdel`, `shadow-groupmod`. Override to add more. |
| `system_groups_setpassword_deployroot` | _(unset, imagebuilder mode)_ | Root directory on the build host where the uci-defaults scripts are deployed. Required for imagebuilder mode — typically set to the OpenWrt imagebuilder output directory. |
| `system_groups_setpassword_deployfile` | `99-set-group` | Filename prefix for the uci-defaults init script. Final path is `{deployroot}/etc/uci-defaults/{deployfile}-{groupname}`. |

## Variables

Since you don't want to define your groups for every host individually, you need to place your variable somewhere every host has access to it. In this example the `system_groups` variable will be defined in the scope of an Ansible group called tags_allhosts.

`./group_vars/tags_allhosts.yaml`
```yaml
system_groups:
  ansiblesudo:
    state: present
    gid: 9000
  sudo:
    state: present
    gid: 9001
  obsoletegroup:
    state: absent
```

Groups will be defined within the dict variable `system_groups` with the attributes described in the [Ansible Group module docs](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/group_module.html).

This role has a dependency to [imp1sh.ansible_managemynetwork.ansible_packages](/junicast/docs/AnsibleManagemynetworkCollection/rolePackages) and will install the required packages automatically on OpenWrt.

### Group attributes

Each key in `system_groups` is the group name. The value is a dictionary of attributes forwarded to [`ansible.builtin.group`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/group_module.html).

| Attribute | Type | Description |
|-----------|------|-------------|
| `gid` | int | Numeric group ID (GID) |
| `state` | string | `present` (default) or `absent` (removes the group) |
| `system` | bool | Create as system group |
| `force` | bool | Delete group even if it's a user's primary group |
| `local` | bool | Force use of local command alternatives (e.g. `lgroupadd`) |
| `non_unique` | bool | Allow non-unique GIDs (requires `gid`) |
| `gid_max` | int | Override GID_MAX from `/etc/login.defs` for group creation (Linux only) |
| `gid_min` | int | Override GID_MIN from `/etc/login.defs` for group creation (Linux only) |

## Host association
Whether or not a group is deployed on a system is defined within `system_groups_create_on_hosts` and `system_groups_create_on_hostgroups`. First one for defining on an individual host basis, second one on a group level. Here is an example:

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

The group names correspond to the group names in Ansible, here it's a dynamic Netbox inventory using netbox tags.

## Remove groups
Make sure the group is associated with the hosts or hostgroups you want to uninstall from. Set the `state` attribute to `absent`. Run your playbook.
