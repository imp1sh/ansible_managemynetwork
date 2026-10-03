# Changelog

## Unreleased

### Breaking Changes

#### NetBox credential variable renames

The following variables have been renamed across all NetBox-related roles to establish a consistent, shared credential namespace:

| Old variable | New variable | Affected roles |
|---|---|---|
| `NETBOX_URL` | `mmn_netbox_url` | `ansible_netboxnewdevice`, `ansible_netbox2yaml` |
| `NETBOX_TOKEN` | `mmn_netbox_token` | `ansible_netboxnewdevice`, `ansible_netbox2yaml` |

**Migration:** Define `mmn_netbox_url` and `mmn_netbox_token` (vault-encrypted) in `group_vars/all/netbox.yml` or equivalent. Remove any `NETBOX_URL`/`NETBOX_TOKEN` definitions from playbooks and vars files.

#### `ansible_netboxnewdevice` — crawl mode is now the default

The role now gathers facts from the target host by default (`mmn_netbox_crawl_enabled: true`) and auto-fills manufacturer, device type, serial, platform, and interfaces/IPs. To restore the original pure-wizard behaviour, set `mmn_netbox_crawl_enabled: false`.

### Features

- **`ansible_netboxnewdevice`**: New crawl mode that gathers Ansible facts from the target host and auto-matches manufacturer and device type against existing NetBox records
- **`ansible_netboxnewdevice`**: Checks for existing device by hostname and pre-fills all known fields from the existing record; only prompts for missing fields
- **`ansible_netboxnewdevice`**: Interactive interface selection — user picks which interfaces to create in NetBox
- **`ansible_netboxnewdevice`**: Interactive IP address selection per interface — user chooses which IPv4/IPv6 addresses to assign
- **`ansible_netboxnewdevice`**: Primary IP selection — prompts for primary IPv4 and IPv6 after assigning addresses
- **`ansible_netboxnewdevice`**: All selectors (manufacturer, device type, device role, platform, site) support creating new records inline via `create` keyword
- **`ansible_netboxnewdevice`**: New `mmn_netbox_force_prompt` variable to bypass existing-device detection and prompt for everything
- **`ansible_netboxnewdevice`**: New `platform.yml` task for platform selection with auto-detect, pick, or create

### Fixes

- **`ansible_psqlserver`**: Fix missing `priv` parameter in container mode — role privileges (e.g. `CREATE` on database) were silently ignored when running PostgreSQL in a container. Added a `postgresql_privs` task to grant privileges after user creation.
