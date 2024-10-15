# imp1sh.ansible_managemynetwork.ansible_openwrtwireless

This ansible role manages wireless connectivity for your OpenWrt node. In the filesystem the config file is `/etc/config/wireless`. It manages wifi-devices on the one hand and wifi-interfaces on the other.
For possible attributes see the the [OpenWrt wifi docs](https://openwrt.org/docs/guide-user/network/wifi/basic).
Best practice for a new device is to experiment with Luci and make your target config and then implement it in Ansible. This is a straight forward process as variable names correspond to UCI naming.

## Example Configuration

Interfaces:
```yaml
openwrt_wifi_interfaceshost:
  wifi1_5g:
    mode: "ap"
    device: "radio1"
    network: "INSECURE"
    encryption: "psk2"
    key: "asdfasdf"
    ssid: "wifi1"
  wifi2_5g:
    mode: "ap"
    device: "radio1"
    network: "SECURE"
    encryption: "sae"
    key: "asdfasdf"
    ssid: "wifi2"
  wifi3_5g:
    mode: "ap"
    device: "radio1"
    network: "MGMT"
    encryption: "psk2"
    key: "asdfasdf"
    ssid: "wifi3"
  wifi1_2g:
    mode: "ap"
    device: "radio0"
    network: "INSECURE"
    encryption: "psk2"
    key: "asdfasdf"
    ssid: "wifi1-legacy"
```
Devices:
```yaml
openwrt_wifi_deviceshost:
  radio0:
    type: "mac80211"
    path: "pci0000:00/0000:00:02.5/0000:05:00.0"
    band: "2g"
    htmode: "HE20"
    channel: "auto"
    cell_density: 0
  radio1:
    type: "mac80211"
    path: "pci0000:00/0000:00:02.5/0000:05:00.0+1"
    band: "5g"
    htmode: "HE80"
    channel: "auto"
    cell_density: 0
```

## Managing multiple devices

> This docs need rework. The role recently switched to:
- openwrt_wifi_deviceshost
- openwrt_wifi_devicesgroup
- openwrt_wifi_interfaceshost
- openwrt_wifi_interfacesgroup
Now things get a bit easier, but below here the docs are basically wrong.

Group up your devices by your needs. In this example there is one site with two different wifi cards.

group name: tags_asiarf_aw7915-npd
```yaml
openwrt_wifi_deviceshost:
  radio0:
    type: "mac80211"
    path: "pci0000:00/0000:00:02.5/0000:05:00.0"
    band: "2g"
    htmode: "HE20"
    channel: "auto"
    cell_density: 0
  radio1:
    type: "mac80211"
    path: "pci0000:00/0000:00:02.5/0000:05:00.0+1"
    band: "5g"
    htmode: "HE80"
    channel: "auto"
    cell_density: 0
openwrt_wifi_interfaces_aw7915:
  wasgeistreiches_5g:
    device: "radio1"
  spargeltarzan_5g:
    device: "radio1"
  quagermark_5g:
    device: "radio1"
  wasgeistreiches_2g:
    device: "radio0"
  spargeltarzan_2g:
    device: "radio0"
  quagermark_2g:
    device: "radio0"
```
group name: tags_wle600vx
```yaml
openwrt_wifi_devices:
  radio0:
    type: "mac80211"
    path: "soc/d0070000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0"
    band: "5g"
    htmode: "VHT80"
    channel: "auto"
openwrt_wifi_interfaces_wle600v:
  wasgeistreiches_5g:
    device: "radio0"
  spargeltarzan_5g:
    device: "radio0"
  quagermark_5g:
    device: "radio0"
```

group name: sites_StandortA
The `device` attribute is not set in the variables as it does not relate to the site but to the device type.
```yaml
openwrt_wifi_interfaces_standorta:
  wifi1_5g:
    mode: "ap"
    network: "INSECURE"
    encryption: "psk2"
    key: "asdfasdf"
    ssid: "wifi1"
  wifi2_5g:
    mode: "ap"
    network: "SECURE"
    encryption: "sae"
    key: "asdfasdf"
    ssid: "wifi2"
  wifi3_5g:
    mode: "ap"
    network: "MGMT"
    encryption: "psk2"
    key: "asdfasdf"
    ssid: "wifi3"
  wifi1_2g:
    mode: "ap"
    network: "INSECURE"
    encryption: "psk2"
    key: "asdfasdf"
    ssid: "wifi1-legacy"
```

In order to merge those `openwrt_wifi_interfaces_xyz` variables you place some actions in your playbook.
Playbook: role_openwrtwireless.yml
```yaml
- hosts: tags_access-point
  pre_tasks:
    - name: combine wifi interfaces with site Standort A
      set_fact:
        openwrt_wifi_interfaces: "{{ openwrt_wifi_interfaces|default({}) | combine(openwrt_wifi_interfaces_standorta, recursive=true) }}"
      when: openwrt_wifi_interfaces_standorta is defined
    - name: combine wifi interfaces with tag aw7915
      set_fact:
        openwrt_wifi_interfaces: "{{ openwrt_wifi_interfaces|default({}) | combine(openwrt_wifi_interfaces_aw7915, recursive=true) }}"
      when: openwrt_wifi_interfaces_aw7915 is defined
    - name: combine wifi interfaces with tag wle600v
      set_fact:
        openwrt_wifi_interfaces: "{{ openwrt_wifi_interfaces|default({}) | combine(openwrt_wifi_interfaces_wle600v, recursive=true) }}"
      when: openwrt_wifi_interfaces_wle600v is defined
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_openwrtwireless

```
