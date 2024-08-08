# imp1sh.ansible_managemynetwork.ansible_openwrtpackages

> Role is deprecated and will not be developed further, please use [imp1sh.ansible_managemynetwork.ansible_packages](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_packages) instead.

This role manages opkg packages on OpenWrt nodes.
You can install packages for a specific host:

```yaml
openwrt_packages_installhost:
  - "vim-fuller"
  - "htop"
  - "vnstat2"
```

You can also install packages for a group of nodes. You can specify in `./group_vars/allhosts.yml` using the variable `openwrt_packagesgroup`:

```yaml
openwrt_packages_installgroup:
  accesspoints:
    - "ath10k-firmware-qca988x"
    - "ath9k-htc-firmware"
    - "ath10k-board-qca988x"
    - "kmod-ath9k-common"
    - "kmod-ath9k"
    - "kmod-ath10k"
  pcenginesapu:
    - "flashrom"
```
You can of course also remove packages, use the corresponding variables:

* openwrt_packages_removehost
* openwrt_packages_removegroup

## Other roles 
Other roles that need specific packages installed, make use of the packages role. In the meta description variables are being set and a dependency to this role is defined. 

Here is an example from `ansible_openwrtrestic`.
```yaml
dependencies:
  - role: imp1sh.ansible_managemynetwork.ansible_openwrtpackages
    vars:
      openwrt_packages_installrole:
        - restic
        - openssh-client-utils
        - shadow-usermod
```
