# imp1sh.ansible_managemynetwork.ansible_alertmanager

Renders Alertmanager configuration — `alertmanager.yml` — onto host-side
bind-mount paths consumed by a podman container. The role is
**container-only**: it performs no package installation and no service
management. The container itself is declared by the caller via the
[`ansible_podman`](../ansible_podman/README.md) role, which invokes this role
as a plugin.

## Design

Following the collection's separation-of-duty principle, `ansible_podman` owns
the container lifecycle (image, network, volumes, restarts) and
`ansible_alertmanager` owns the configuration files that land inside the
container. The podman role renders the config *before* it starts the container,
so the first boot already finds a valid `alertmanager.yml`.

## Variables

### Paths

| Variable | Default | Description |
|----------|---------|-------------|
| `alertmanager_path_config` | **required** | Where `alertmanager.yml` is rendered. Bind-mount into the container (typically `/etc/alertmanager`). No portable default — set in host_vars. |
| `alertmanager_file_config` | `alertmanager.yml` | Main config filename. |

### Ownership / modes

| Variable | Default | Description |
|----------|---------|-------------|
| `alertmanager_owner` | `root` | Owner of rendered files. Match the container image UID. |
| `alertmanager_group` | `root` | Group of rendered files. Match the container image GID. |
| `alertmanager_mode_config` | `0644` | Mode for `alertmanager.yml`. |

### Configuration content

| Variable | Default | Description |
|----------|---------|-------------|
| `alertmanager_config` | `{}` | **Primary input.** Dict mirroring the `alertmanager.yml` structure (`global`, `route`, `receivers`, `inhibit_rules`, `templates`). Rendered as YAML via `to_nice_yaml`. |

### Reload mechanism

| Variable | Default | Description |
|----------|---------|-------------|
| `alertmanager_containername` | `null` | Name of the podman container running alertmanager. When set, config changes notify a handler that restarts the container (most alertmanager settings are only read at startup). |

## Example

```yaml
alertmanager_containername: "alertmanager0"
alertmanager_path_config: "/mnt/cntr/unsynced/alertmanager/config"
alertmanager_config:
  global:
    resolve_timeout: 5m
  route:
    receiver: gotify-bridge
    group_by: ['alertname', 'instance']
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 12h
  receivers:
    - name: gotify-bridge
      webhook_configs:
        - url: 'http://gotifybridge0:8080/gotify_webhook'
          send_resolved: true
```
