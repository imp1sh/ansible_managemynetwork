# imp1sh.ansible_managemynetwork.ansible_users

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_users)

This role manages users for hosts.
It currently supports those Operating Systems:
- Debian
- OpenWrt
- Ubuntu (best effort)
- FreeBSD (best effort)
- ~~Alpine~~ (probably works but no longer supported)
- ~~Arch~~ (probably works but no longer supported)
- ~~Manjaro~~ (probably works but no longer supported)

## OpenWrt specific
When using this with OpenWrt it will install those packages so ansible.builtin.user can do its job:
- shadow-useradd
- sudo

Usually in OpenWrt only the root user is being used but it's actually possible to add additional users, e.g. for backup jobs or whatever. This role is also compatible  with [ansible_openwrtimagebuilder](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtimagebuilder/README.md). It works by implementing an init script that is only run once at first boot of the device, setting the password for the user.

If you do `import_playbook` on the users role but you only want it to run on OpenWrt, use:
```yaml
- name: MMN users
  import_playbook: users.yml
  when: ansible_distribution == 'OpenWrt'
```
while the users playbook looking like this:
```yaml
---
- name: Handling users in Linux, Unix
  hosts: all
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_users
```

## Variables

Since you don't want to define your users for every host individually, you need to place your variable somewhere every host has access to it. In this example the `system_users` variable will be defined in the scope of an Ansible group called tags_allhosts.

`./group_vars/tags_allhosts.yaml`
```yaml
system_users:
  jdenker:
    comment: "Johann Denker"
    uid: 2048
    password: "$6$6FlXAIFWM2v1clqj$pVYUclQuCJ0kDDcg2QFhjgfhjg31rt4FmS8cVKUxsDKSOmasdfasdfasdfaqcQJECEpaiCjasdfsadfm0GxRtsmCNoTh/mlIp9gQDGr97pvUhswZOieSi0"
    shell: "bash"
  "skuchen":
    comment: "Sibille Kuchen"
    uid: 2050
    password: "$6$clsF9Lxzh9JF5LZJ$RhUnTHwDHiLwrLjIkFj2.K0BHh632465gi95g6JSe0BsdafsdfaoCs6141.sA3hz32RGtvMiLXn4NhgfdhjmhsX.zXu4ozlIQTaoQL2xuP9I/"
    shell: "zsh"
```

The password is expected to be encrypted. The easiest way to get such an encrypted password is to use the `mkpasswd` command line tool. Some might even want to put this into ansible-vault encryption on top.
A more complete list of available options can be found in the [role's documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html).

This role has a dependency to [imp1sh.ansible_managemynetwork.ansible_packages](/junicast/docs/AnsibleManagemynetworkCollection/rolePackages) and will install the shell package you choose for the users automatically.

## Host association
Whether or not a users id deployed on a system is defined within `system_users_create_on_hosts` and `system_users_create_on_hostgroups`. First one for defining on an individual host basis, second one on a group level. Here is an example:

```yaml
system_users_create_on_hosts:
  mmustermann:
    - "accounting.example.com"
  sibilledegenhard:
    - "accounting.example.com"
  user1:
    - "xps13.example.com"
    - "macbook.example.com"
  scan:
    - "nas.example.com"
system_users_create_on_hostgroups:
  ansible:
    - "tags_allhosts"
  sysadm_recovery:
    - "tags_allhosts"
  backupuser:
    - "tags_backuptarget_borg"
```

The group names correspond to the group names in Ansible, here it's a dynamic Netbox inventory using netbox tags.

## Remove Users
Just set the `state` attribute of the user to `absent`. If the attribute `state` is not defined it will default to present.

## Shell
You do not give the full path to the shell here, but only the binary name, e.g. `zsh`. If your OS doesn't work with this role or a shell you want is missing, please open [an issue](https://github.com/imp1sh/ansible_managemynetwork/issues).

[Here is](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_users/vars/Debian.yml) a list of supported shells so far.
