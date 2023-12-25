# imp1sh.ansible_managemynetwork.ansible_netbox2yaml

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_netbox2yaml)

This Ansible role generates YAML variable files for the usage in Ansible. This role supports the idea of using Netbox as a [Single Source of Truth](https://en.wikipedia.org/wiki/Single_source_of_truth). In contrast to using the [Ansible Netbox Inventory Module](https://docs.ansible.com/ansible/latest/collections/netbox/netbox/nb_inventory_inventory.html), [Netbox2yaml](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_netbox2yaml) will give you access to basically all information in netbox, not only the information related to the host you run Ansible for.

This is how a basic playbook might look like:

role_netbox2yaml.yml 
```yaml
- hosts: 127.0.0.1
  connection: local
  roles:
    - imp1sh.ansible_managemynetwork.ansible_netbox2yaml
  vars:
    NETBOX_URL: "https://netbox.yourdomain.net/"
    NETBOX_TOKEN: "yoursecurenetboxtoken"
    nb_prefixes_destination: "/home/jochen/ansible/group_vars/tags_ansible-netbox-prefixesfetch.yml"
    nb_devices_destination: "/home/jochen/ansible/group_vars/tags_ansible-netbox-devicesfetch.yml"
    nb_fetch_devices: true
    nb_fetch_prefixes: true
```
The play naturally runs on the ansible host itself as it will generate yaml files. Further you can specify what data you would like to fetch (so far only vms, devices and prefixes). In my special case I'm grouping hosts by using netbox tags, so every host being in the netbox group `ansible-netbox-prefixesfetch` will have access to the data fetch from netbox. You can define that to your likings. Maybe you would like your hosts in the `allhosts` group to have access to the data, then you might want to set
```yaml
nb_prefixes_destination: "/home/jochen/ansible/group_vars/allhosts.yml"
```

This is an idea about how the target format shall look like. This example does not contain the actual amount of attributes.

```yaml
nb_devices:
  myserver.libcom.de:
    id:
    comments:
    device_role:
    device_type:
    platform:
    primary_ip4:
    primary_ip6:
    rack:
    serial:
    site:
    status:
    interfaces:
      eth0:
        id:
        ip4: 
        ip6:
```

## nb_prefixes
The prefixes (IP networks) data fetched from netbox will go to the variable named `nb_prefixes`. This is what a structure might look like:

```yaml
netbox_prefixes:
  RX-DMZ:
    "4":
      prefix: 5.145.135.88/29
    "6":
      gua: 2a00:fe0:3f:2::/64
      ula: fd00:fe0:3f:2::/64
  RX-ROOT:
    "4":
      prefix: 10.10.100.0/22
    "6":
      gua: 2a00:fe0:3f::/48
      ula: fd00:fe0:3f::/48
```

So if you would like to access such an element in Ansible you would use e.g. `nb_prefixes['RX-DMZ']['6']['gua']`.

## nb_devices
Devices are 

```yaml
netbox_devices:
  pc1.libcom.de:
    comments: Rackserver 2HE
    device_type: Rackserver 2HE
    vmbr0:
      description: Upstream Bridge auf enp6s0
      dns_name: pc1.libcom.de
      ip4: 10.11.12.13/29
      ip6: fd00:fe0:1:4f::f/64
  server1.libcom.de:
    comments: Towerserver 6U
    device_type: Towerserver 6U
    vmbr0:
      description: Management Bridge
      dns_name: server1.libcom.de
      ip4: 10.10.129.7/26
      ip6: fd01:4dd0:28d4:7300::e/64
```
This way you can access IP and interface details of any host in netbox directly, e.g. via 
```yaml
nb_devices['pc1.libcom.de']['vmbr0']['ip4']
```
or
```yaml
nb_devices['pc1.libcom.de']['primary_ip6']
```

## nb_vms
As there is data from devices there is also data from virtual machines. Those are geing accessed via the `nb_vms` variable in the same fashion as `nb_devices`.

## Sample Data from Netbox

### IP Address element

IP Address element from netbox. The attribute `key` is the primary key for the object. The attribute `value.assigned_object_id` is a foreign key and points to the object which is described in `value.assigned_object_type` which in this example is `dcim.interface`, meaning the IP object points to an interface object of a device (not a VM) that has the ID `70`.
There may be IP addresses in your Netbox that carry the `status: active` flag and yet are not assigned to an interface. Those will carry a `null` in the `assigned_object_id`. Those need to be filtered out which is an open todo.
```yaml
        {
            "key": 372,
            "value": {
                "address": "fd01:4dd0:28d4:7300::fae/64",
                "assigned_object": {
                    "_occupied": false,
                    "cable": null,
                    "device": {
                        "display": "ax1800.libcom.de",
                        "id": 32,
                        "name": "ax1800.libcom.de",
                        "url": "https://netbox.libcom.de/api/dcim/devices/32/"
                    },
                    "display": "mainbridge",
                    "id": 70,
                    "name": "mainbridge",
                    "url": "https://netbox.libcom.de/api/dcim/interfaces/70/"
                },
                "assigned_object_id": 70,
                "assigned_object_type": "dcim.interface",
                "created": "2023-03-15T16:20:12.317473Z",
                "custom_fields": {
                    "ansible_gateway": null
                },
                "description": "",
                "display": "fd01:4dd0:28d4:7300::fae/64",
                "dns_name": "",
                "family": {
                    "label": "IPv6",
                    "value": 6
                },
                "id": 372,
                "last_updated": "2023-03-15T16:20:12.317482Z",
                "nat_inside": null,
                "nat_outside": null,
                "role": null,
                "status": {
                    "label": "Active",
                    "value": "active"
               },
                "tags": [],
                "tenant": null,
                "url": "https://netbox.libcom.de/api/ipam/ip-addresses/372/",
                "vrf": null
            }
        },
```

### Interface element

```yaml
"nb_interfaces_fetched": [
        {
            "key": 48,
            "value": {
                "_occupied": false,
                "bridge": null,
                "cable": null,
                "connected_endpoint": null,
                "connected_endpoint_reachable": null,
                "connected_endpoint_type": null,
                "count_fhrp_groups": 0,
                "count_ipaddresses": 0,
                "created": "2021-12-27T00:00:00Z",
                "custom_fields": {},
                "description": "anotherswitch.libcom.de port 6",
                "device": {
                    "display": "mysmartswitch.libcom.de",
                    "id": 17,
                    "name": "mysmartswitch.libcom.de",
                    "url": "https://netbox.libcom.de/api/dcim/devices/17/"
                },
                "display": "eth2",
                "duplex": null,
                "enabled": true,
                "id": 48,
                "label": "",
                "lag": null,
                "last_updated": "2021-12-27T13:58:41.335588Z",
                "link_peer": null,
                "link_peer_type": null,
                "mac_address": null,
                "mark_connected": false,
                "mgmt_only": false,
                "mode": null,
                "module": null,
                "mtu": null,
                "name": "eth2",
               "parent": null,
                "rf_channel": null,
                "rf_channel_frequency": null,
                "rf_channel_width": null,
                "rf_role": null,
                "speed": null,
                "tagged_vlans": [],
                "tags": [],
                "tx_power": null,
                "type": {
                    "label": "1000BASE-T (1GE)",
                    "value": "1000base-t"
                },
                "untagged_vlan": null,
                "url": "https://netbox.libcom.de/api/dcim/interfaces/48/",
                "vrf": null,
                "wireless_lans": [],
                "wireless_link": null,
                "wwn": null
            }
        },
]
```

### Device element
```yaml
       {
            "key": 22,
            "value": {
                "airflow": null,
                "asset_tag": null,
                "cluster": null,
                "comments": "",
                "config_context": {},
                "created": "2022-06-04T00:00:00Z",
                "custom_fields": {},
                "device_role": {
                    "display": "Laptop",
                    "id": 13,
                    "name": "Laptop",
                    "slug": "laptop",
                    "url": "https://netbox.libcom.de/api/dcim/device-roles/13/"
                },
                "device_type": {
                    "display": "xps13",
                    "id": 15,
                    "manufacturer": {
                        "display": "Dell",
                        "id": 2,
                        "name": "Dell",
                        "slug": "dell",
                        "url": "https://netbox.libcom.de/api/dcim/manufacturers/2/"
                    },
                    "model": "xps13",
                    "slug": "xps13",
                    "url": "https://netbox.libcom.de/api/dcim/device-types/15/"
                },
                "display": "xps13.libcom.de",
                "face": null,
                "id": 22,
                "last_updated": "2023-03-11T16:31:47.598064Z",
                "local_context_data": null,
                "location": null,
                "name": "xps13.libcom.de",
                "parent_device": null,
                "platform": null,
                "position": null,
                "primary_ip": {
                    "address": "fd01:4dd0:28d4:7337::bb2/64",
                    "display": "fd01:4dd0:28d4:7337::bb2/64",
                    "family": 6,
                    "id": 295,
                    "url": "https://netbox.libcom.de/api/ipam/ip-addresses/295/"
                },
                "primary_ip4": null,
                "primary_ip6": {
                    "address": "fd01:4dd0:28d4:7337::bb2/64",
                    "display": "fd01:4dd0:28d4:7337::bb2/64",
                    "family": 6,
                    "id": 295,
                    "url": "https://netbox.libcom.de/api/ipam/ip-addresses/295/"
                },
                "rack": null,
                "serial": "3BQC0G2",
                "site": {
                    "display": "Strasse Nummer",
                    "id": 1,
                    "name": "Strasse Nummer",
                    "slug": "strasse-nummer",
                    "url": "https://netbox.libcom.de/api/dcim/sites/1/"
                },
                "status": {
                    "label": "Active",
                    "value": "active"
                },
                "tags": [
                    {
                        "color": "c0c0c0",
                        "display": "Allhosts",
                        "id": 6,
                        "name": "Allhosts",
                        "slug": "allhosts",
                        "url": "https://netbox.libcom.de/api/extras/tags/6/"
                    },
                    {
                        "color": "9e9e9e",
                        "display": "Ansible Netbox Prefixesfetch",
                        "id": 51,
                        "name": "Ansible Netbox Prefixesfetch",
                        "slug": "ansible-netbox-prefixesfetch",
                        "url": "https://netbox.libcom.de/api/extras/tags/51/"
                    },
                    {
                        "color": "3f51b5",
                        "display": "Ansiblemanaged",
                        "id": 16,
                        "name": "Ansiblemanaged",
                        "slug": "ansiblemanaged",
                        "url": "https://netbox.libcom.de/api/extras/tags/16/"
                    },
                    {
                        "color": "9e9e9e",
                        "display": "Borgmatic",
                        "id": 26,
                        "name": "Borgmatic",
                        "slug": "borgmatic",
                        "url": "https://netbox.libcom.de/api/extras/tags/26/"
                    },
                    {
                        "color": "673ab7",
                        "display": "Desktop",
                        "id": 10,
                        "name": "Desktop",
                        "slug": "desktop",
                        "url": "https://netbox.libcom.de/api/extras/tags/10/"
                    },
                    {
                        "color": "9e9e9e",
                        "display": "Nftables",
                        "id": 22,
                        "name": "Nftables",
                        "slug": "nftables",
                        "url": "https://netbox.libcom.de/api/extras/tags/22/"
                    },
                    {
                        "color": "ffc107",
                        "display": "Von mir verwaltet",
                        "id": 4,
                        "name": "Von mir verwaltet",
                        "slug": "von-mir-verwaltet",
                        "url": "https://netbox.libcom.de/api/extras/tags/4/"
                    }
                ],
                "tenant": null,
                "url": "https://netbox.libcom.de/api/dcim/devices/22/",
                "vc_position": null,
                "vc_priority": null,
                "virtual_chassis": null
            }
        },
```
