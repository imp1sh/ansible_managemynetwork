# imp1sh.ansible_managemynetwork.ansible_packages

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_packages)

This is a role that enables you to install or remove packages in Ansible.

> Remember that for every distribution the packages have specific names.
{.is-warning}

## per Host
You can define to install packages on a host level in Ansible

```yaml
packages_installhost: "qemu-guest-agent, python3, python3-setuptools, python3-pip, python3-pylibmc, python3-pymysql, python3-mysqldb"
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
Ansible roles should be atomar / modular. Several roles install packages which is a bad idea in general. To make it more smooth, just call this role and hand over the packages you want.

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
