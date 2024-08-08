# imp1sh.ansible_managemynetwork.ansible_packages

This is a role that enables you to install or remove packages in Ansible.

> Remember that for every distribution some packages have specific names.
{.is-warning}

Formerly there was a dedicated role `ansible_openwrtpackages` which was merged into this very role. So there is only one role for installing packages for common Linux distributions aw well as for OpenWrt. There is one special case for OpenWrt. It's when the [ansible_openwrtimagebuilder](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_openwrtimagebuilder) role is being used. Then no packages are actually installed but a list is being generated for building the OpenWrt image including those packages. 

## per Host
You can define to install packages on a host level in Ansible

```yaml
packages_installhost:
  - qemu-guest-agent
  - python3
  - python3-setuptools
  - python3-pip
  - python3-pylibmc
  - python3-pymysql
  - python3-mysqldb
```

If you want to remove packages, use the `packages_removehost` variable instead.

## per Group
If you would like to install packages for several hosts you need to use Ansible groups.
Define your variables where every host can access them, e.g. in `group_vars/all.yml`.

```yaml
packages_installgroup: 
  platforms_ubuntu:
    - "nmap"
    - "tcpdump"
    - "mc"
    - "git"
    - "screen"
    - "vim"
  tags_desktop:
    - "gvim"
```

This will install packages on hosts that belong to the groups *platforms_ubuntu* and *tags_desktop*.

## Call from different role
Ansible roles should be atomar / modular. There are roles that install packages even when this is not their purpose. To make it more smooth, just call this role and hand over the packages you want.

Here you can see how the chrony role does it:

```yaml
- name: Set package name for calling packages role
  ansible.builtin.set_fact:
    packages_installrole: "{{ chronyd_packagename }}"
- name: install additional packages for snap or flatpak
  ansible.builtin.include_role:
    name: imp1sh.ansible_managemynetwork.ansible_packages
```

packages_installrole is a *list* of packages that shall get installed. `chronyd_packagename` here is only one item: `chrony` for Debian.
