# imp1sh.ansible_managemynetwork.ansible_openwrtuhttpd

OpenWrt uses the lightweight uhttpd webserver in order to make the LUCI WebGUI available. This role administers the configuration for that webservice.

This is how a playbook can look like:

role_openwrtuhttpd.yml
```yaml
---
- hosts: platforms_openwrt
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_openwrtuhttpd
```

Even without a single variable set the role will deploy a default configuration equal to how the OpenWrt configuration look like on a fresh install. The only difference is that it will redirect to https as a default.

If you would like to make modifications to the [default values](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtuhttpd/defaults/main.yml) of the role, just define them in your Ansible environment.

For a full list of available configuration options, look at the [OpenWrt's uhttpd documentation](https://openwrt.org/docs/guide-user/services/webserver/uhttpd).

## Certificates

If no certificate is given it will use the default certificate and key
```
/etc/uhttpd.key
/etc/uhttpd.crt
```

It will also look for a key and cert in:
```
/etc/acme/{{ inventory_hostname }}/{{ inventory_hostname }}.cer
/etc/acme/{{ inventory_hostname }}/{{ inventory_hostname }}.key
```
and will use that if found. You can change `/etc/acme/{{ inventory_hostname }}/` by configuring the variable `openwrt_uhttpd_cert_searchpath`.


