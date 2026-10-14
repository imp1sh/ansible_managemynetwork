# imp1sh.ansible_managemynetwork.ansible_netbootxyz

Templates `local-vars.ipxe` and custom iPXE installer scripts (e.g. a headless
Talos metal installer) into the bind-mounts of a self-hosted
[netboot.xyz](https://netboot.xyz) container. Designed to be invoked via the
`netbootxyz` podman plugin of the `ansible_podman` role.

## How it works

The compiled netboot.xyz iPXE bootloader TFTP-fetches `local-vars.ipxe` from the
local TFTP server **before** it chains `menu.ipxe`. Anything chained from
`local-vars.ipxe` therefore pre-empts the interactive menu for matching hosts.
Unmatched MACs fall through and get the normal netboot.xyz menu unchanged.

This lets you auto-route specific hosts (by MAC) straight into an installer with
no menu and no user interaction, while leaving every other PXE client on the
network untouched.

## Requirements

- A self-hosted netboot.xyz container whose TFTP root and assets directory are
  bind-mounted on the podman host.
- The TFTP root must be writable by Ansible and owned by the container's TFTP
  user (dnsmasq runs with `--tftp-secure`). In the stock netboot.xyz image that
  user is `nbxyz` (uid 1000), which typically maps to a host user such as
  `setup` (uid 1000). Set `netbootxyz_owner`/`netbootxyz_group` accordingly.

## Variables

| Variable | Required | Default | Description |
|----------|:--------:|---------|-------------|
| `netbootxyz_config_dir` | yes | `/filer0/netbootxyz/config/menus` | Host-side TFTP root (bind-mount of `/config/menus`). `local-vars.ipxe` is placed here. |
| `netbootxyz_assets_dir` | yes | `/filer0/netbootxyz/assets` | Host-side nginx assets root. Custom iPXE scripts go under `custom/`. |
| `netbootxyz_assets_url` | yes | `https://netbootassets.lpv4.net` | HTTPS URL iPXE uses to fetch custom scripts (fronted by traefik). |
| `netbootxyz_owner` | no | `setup` | Owner for deployed files (must equal the in-container TFTP user uid). |
| `netbootxyz_group` | no | `setup` | Group for deployed files. |
| `netbootxyz_pxe_routes` | no | `[]` | List of `{mac, chain_url}` entries; each renders one `iseq ${mac} … && chain … \|\|` line. |
| `netbootxyz_deploy_talos_installer` | no | `true` | Templating the built-in `talos-metal.ipxe` into `assets/custom/`. |
| `netbootxyz_talos_version` | no | `v1.14.2` | Talos version to PXE-install. Set to `{{ talos_version }}` to track your cluster. |
| `netbootxyz_talos_mirror` | no | `https://cdn.siderolabs.dev/releases` | Sidero release CDN. |
| `netbootxyz_talos_platform` | no | `metal` | `talos.platform` kernel arg. |
| `netbootxyz_talos_console` | no | `console=ttyS0 console=tty0` | Console kernel args. |

## Example

`host_vars/filer0.t.libcom.de.yml`:

```yaml
podman_container_plugin_netbootxyz:
  - "netbootxyz0"
netbootxyz_pxe_routes:
  - mac: "52:54:00:8a:3f:c1"   # talos0
    chain_url: "https://netbootassets.lpv4.net/custom/talos-metal.ipxe"
netbootxyz_talos_version: "{{ talos_version }}"
```

## Notes

- `local-vars.ipxe` is managed wholesale by this role; manual edits are
  overwritten on the next run. Add hosts via `netbootxyz_pxe_routes`.
- No container restart is required: dnsmasq TFTP and nginx serve files live.
- The Talos installer supplies no machine config, so the node enters the Talos
  maintenance state after boot, ready for `talosctl apply`.
