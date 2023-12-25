# imp1sh.ansible_managemynetwork.ansible_openwrtservices
With this Ansible role you can enable or disable services on your OpenWrt node.

Example activate:

```yaml
openwrt_services_enabled:
  - babeld
```
deactivate:

```yaml
openwrt_services_disabled:
  - bmx7
```
There is also the possibility to run single line commands at boot:

```yaml
openwrt_services_scriptlinesafterboot:
  - "/usr/bin/mycommand myparameters"
```
