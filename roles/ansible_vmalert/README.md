# imp1sh.ansible_managemynetwork.ansible_vmalert

Renders vmalert rule files onto host-side bind-mount paths consumed by a
podman container. The role is **container-only**: it performs no package
installation and no service management. The container itself is declared by
the caller via the [`ansible_podman`](../ansible_podman/README.md) role, which
invokes this role as a plugin.

## Design

Following the collection's separation-of-duty principle, `ansible_podman` owns
the container lifecycle (image, network, volumes, restarts) and
`ansible_vmalert` owns the rule files that land inside the container. The
podman role renders the rules *before* it starts the container, so the first
boot already finds valid rule files.

## Variables

### Paths

| Variable | Default | Description |
|----------|---------|-------------|
| `vmalert_path_rules` | **required** | Where rule files are rendered. Bind-mount into the container (typically `/etc/vmalert/rules`). No portable default — set in host_vars. |

### Ownership / modes

| Variable | Default | Description |
|----------|---------|-------------|
| `vmalert_owner` | `root` | Owner of rendered files. Match the container image UID. |
| `vmalert_group` | `root` | Group of rendered files. Match the container image GID. |
| `vmalert_mode_rules` | `0644` | Mode for rule files. |

### Rule files

| Variable | Default | Description |
|----------|---------|-------------|
| `vmalert_rules` | `{}` | **Primary input.** Dict keyed by rule-file stem; each value is a list of group objects as vmalert/Prometheus expects under `groups:`. Annotation strings containing `{{ $labels.* }}` or `{{ $value }}` MUST be tagged `!unsafe`. |

### Reload mechanism

| Variable | Default | Description |
|----------|---------|-------------|
| `vmalert_containername` | `null` | Name of the podman container running vmalert. When set, rule changes notify a handler that restarts the container. |

## Example

```yaml
vmalert_containername: "vmalert0"
vmalert_path_rules: "/mnt/cntr/unsynced/vmalert/0/rules"
vmalert_rules:
  node_alerts:
    - name: node-alerts
      interval: 1m
      rules:
        - alert: NodeDown
          expr: 'up{job=~"openwrt|debian"} == 0'
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: !unsafe "Node {{ $labels.instance }} is down"
            description: !unsafe "{{ $labels.instance }} has been unreachable for 2 minutes."
```
