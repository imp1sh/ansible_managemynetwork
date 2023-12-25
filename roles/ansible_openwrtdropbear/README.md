# imp1sh.ansible_managemynetwork.ansible_openwrtdropbear

This role manages the SSH service. OpenWrt uses dropbear in contrast to many other system, that use OpenSSH.

This is an example dropbear configuration:
```yaml
openwrt_dropbear_passwordauth: "on"
openwrt_dropbear_rootpasswordauth: "on"
openwrt_dropbear_port: "22"
```
You can provide your OpenWrt devices with public keys. You can do that for a specific host, by defining this variable in your Ansible host definition:
```yaml
openwrt_dropbear_keyshost:
  - "ssh-rsa AAAAB3NzaC1yc2EAAAAyourpublickey9Y100zBxWp0= user@hostname"
```
When you would like to have keys provided to multiple systems you need to use an Ansible group. Define in the `allhosts` scope. This example assigns the keys to the group name `platforms_openwrt`:
```yaml
openwrt_dropbear_keysgroup:
  platforms_openwrt:
    - "ssh-rsa AAAAB3NzaC1yc2EAAAAyourpublickey9Y100zBxWp0= user@hostname"
    - "ssh-rsa AAAAB3NzaC1ya2EEAByourpublickey9Y100zB2xWp0= user2@hostname"
```

More parameter are supported, see:[OpenWrt dropbear docs](https://openwrt.org/docs/guide-user/base-system/dropbear).
