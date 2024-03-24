# imp1sh.ansible_managemynetwork.ansible_openwrtservices
With this Ansible role you can enable or disable services on your OpenWrt node.

Example activate:

```yaml
openwrt_services_enabledhost:
  - babeld
```
deactivate:

```yaml
openwrt_services_disabledhost:
  - bmx7
```

If you would like to prefer to define this on a group level use the group name as dict key like this:
```yaml
openwrt_services_enabledgroup:
  mygroupname:
    - babeld
```
You can also set `openwrt_services_enabledrole` (ofc also disable) if you call the role from somewhere else.

There is also the possibility to run single line commands at boot:

```yaml
openwrt_services_scriptlinesafterboot:
  - "/usr/bin/mycommand myparameters"
```
