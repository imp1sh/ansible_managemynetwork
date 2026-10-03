# imp1sh.ansible_managemynetwork.ansible_netboxnewdevice

Interactive wizard that creates or updates a device in [Netbox](https://github.com/netbox-community/netbox). Unlike most roles in this collection it is **not** meant for unattended automation — it pauses and prompts for decisions that cannot be auto-detected, making it a convenient tool for ad-hoc device onboarding.

## Two Modes

### Crawl Mode (default)

When `mmn_netbox_crawl_enabled: true` (the default), the role:

1. **Crawls facts** from the target host via the Ansible `setup` module.
2. **Auto-discovers** manufacturer and device type by matching `ansible_system_vendor` and `ansible_product_name` against existing NetBox records.
3. **Pre-fills** serial number, hostname, and platform from facts.
4. **Checks** whether a device with the same name already exists in NetBox. If so, existing fields are reused.
5. **Prompts interactively** only for fields that could not be auto-detected (typically: device role, site, and status for new devices).
6. **Creates or updates** the device in NetBox.
7. **Creates interfaces** and **assigns IP addresses** from crawled Ansible network facts.

### Pure Wizard Mode

Set `mmn_netbox_crawl_enabled: false` to restore the original behaviour: every field is prompted manually, no crawling occurs. Useful when running against `localhost` or when `gather_facts` is disabled.

## Requirements

- The [`netbox.netbox`](https://galaxy.ansible.com/ui/repo/published/netbox/netbox/) Ansible collection must be installed on the controller.
- A reachable Netbox instance with an API token that has write permissions for devices, device types, manufacturers, sites, device roles, interfaces, and IP addresses.
- In crawl mode, the target host must be reachable via SSH and `gather_facts` must be enabled (the default).

## Variables

### Connection (shared across all MMN NetBox roles)

| Variable | Required | Description |
|----------|:--------:|-------------|
| `mmn_netbox_url` | yes | Base URL of the Netbox instance, e.g. `https://netbox.example.com`. Store vault-encrypted in `group_vars/all/netbox.yml`. |
| `mmn_netbox_token` | yes | Netbox API token with write permissions. Store vault-encrypted in `group_vars/all/netbox.yml`. |

### Behavioural

| Variable | Default | Description |
|----------|---------|-------------|
| `mmn_netbox_crawl_enabled` | `true` | Enable crawl mode (gather facts, auto-fill fields). Set `false` for pure wizard. |
| `mmn_netbox_create_interfaces` | `true` | Create/update interfaces in NetBox from crawled Ansible facts. |
| `mmn_netbox_assign_ip_addresses` | `true` | Assign IP addresses to interfaces in NetBox from crawled facts. |

### Credential Setup

Define credentials once in `group_vars/all/netbox.yml` (vault-encrypted):

```yaml
mmn_netbox_url: "https://netbox.example.com"
mmn_netbox_token: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...
```

Encrypt the token with:
```bash
read -rs _tok; ansible-vault encrypt_string --name mmn_netbox_token "$_tok"; unset _tok
```

## Fact-to-NetBox Field Mapping (crawl mode)

| Ansible Fact | NetBox Field |
|---|---|
| `ansible_hostname` | device name (pre-filled, can be overridden) |
| `ansible_system_vendor` | manufacturer (matched against existing NetBox manufacturers) |
| `ansible_product_name` | device type model (matched against existing device types for the manufacturer) |
| `ansible_product_serial` | device serial |
| `ansible_distribution` + `ansible_distribution_major_version` | platform slug (e.g. `debian12`) |
| `ansible_interfaces` | dcim.interfaces (excluding loopback) |
| Per-interface `ipv4` / `ipv6` | ipam.ip_addresses (assigned to the corresponding interface) |

Fields that cannot be auto-detected and are always prompted (unless found on an existing device):

- **Device role** (server, switch, router, firewall, ...)
- **Site** (physical location)
- **Status** (defaults to `active` for newly crawled devices)
- **Description** (optional)

## Example Playbook (crawl mode)

```yaml
---
- name: Crawl and register device in Netbox
  hosts: myhost.example.com
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_netboxnewdevice
```

Credentials come from `group_vars/all/netbox.yml` — no need to pass them in the playbook.

## Example Playbook (pure wizard mode)

```yaml
---
- name: Manually create a new device in Netbox
  hosts: localhost
  gather_facts: false
  vars:
    mmn_netbox_crawl_enabled: false
  roles:
    - imp1sh.ansible_managemynetwork.ansible_netboxnewdevice
```

## Idempotent Updates

Re-running the role against an already-registered device will:
- Detect the existing device by hostname
- Pre-fill all known fields from the existing record
- Skip prompts for fields that are already set
- Update the device (and interfaces/IPs) with any changed values

This makes it safe to run repeatedly.
