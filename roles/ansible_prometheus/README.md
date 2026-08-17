# imp1sh.ansible_managemynetwork.ansible_prometheus

Renders Prometheus **server** configuration — `prometheus.yml` plus rule files — onto host-side bind-mount paths consumed by a podman container. The role is **container-only**: it performs no package installation and no service management. The container itself is declared by the caller via the [`ansible_podman`](../ansible_podman/README.md) role, which invokes this role as a plugin.

## Design

Following the collection's separation-of-duty principle, `ansible_podman` owns the container lifecycle (image, network, volumes, restarts) and `ansible_prometheus` owns the configuration files that land inside the container. The podman role renders the config *before* it starts the container, so the first boot already finds a valid `prometheus.yml`.

The role is intentionally limited to the Prometheus server. Alertmanager, Grafana, exporters, etc. belong to their own roles.

## Variables

### Paths (host bind-mount roots)

| Variable | Default | Description |
|----------|---------|-------------|
| `prometheus_path_config` | `/mnt/cntr/unsynced/prometheus/0/etc` | Where `prometheus.yml` is rendered. Bind-mount into the container (typically `/etc/prometheus`). |
| `prometheus_path_rules` | `{{ prometheus_path_config }}/rules` | Where rule files are rendered. Bind-mount into the container (typically `/etc/prometheus/rules`). |
| `prometheus_path_data` | `/mnt/cntr/unsynced/prometheus/0/data` | TSDB data directory. Bind-mount into the container (typically `/prometheus`). |
| `prometheus_file_config` | `prometheus.yml` | Main config filename. |

### Ownership / modes

| Variable | Default | Description |
|----------|---------|-------------|
| `prometheus_owner` | `nobody` | Owner of rendered files and the data dir. Match the container image UID. |
| `prometheus_group` | `nogroup` | Group of rendered files and the data dir. Match the container image GID. |
| `prometheus_mode_config` | `0640` | Mode for `prometheus.yml`. |
| `prometheus_mode_rules` | `0644` | Mode for rule files. |
| `prometheus_mode_data` | `0750` | Mode for the TSDB data directory. |

The official `prom/prometheus` image runs as `nobody`/`nogroup` (UID/GID 65534); the defaults match. Override per image if yours differs.

### prometheus.yml content

| Variable | Default | Description |
|----------|---------|-------------|
| `prometheus_global_scrape_interval` | `15s` | `global.scrape_interval`. |
| `prometheus_global_scrape_timeout` | `10s` | `global.scrape_timeout`. |
| `prometheus_global_evaluation_interval` | `15s` | `global.evaluation_interval`. |
| `prometheus_external_labels` | `{}` | `global.external_labels` dict. Omitted when empty. |
| `prometheus_alertmanagers` | `null` | `alerting.alertmanagers` stanza. Omitted when `null`. |
| `prometheus_remote_write` | `null` | `remote_write` stanza. Omitted when `null`. |
| `prometheus_remote_read` | `null` | `remote_read` stanza. Omitted when `null`. |
| `prometheus_scrape_configs` | `[]` | **Primary input.** List of `scrape_config` stanzas (each requires `job_name`). |
| `prometheus_rules` | `{}` | Dict keyed by rule-file stem; each value is a list of group objects. |
| `prometheus_rules_glob` | `rules/*.rules.yml` | Glob pattern emitted in `prometheus.yml`'s `rule_files` section. **Container-internal** path — must match where you mount `prometheus_path_rules` inside the container (default assumes `/etc/prometheus/rules/`). |

### Reload

| Variable | Default | Description |
|----------|---------|-------------|
| `prometheus_containername` | `null` | Podman container name. When set, config/rule changes notify a handler that runs `podman exec <name> kill -HUP 1` (Prometheus reloads `prometheus.yml` and rule files on SIGHUP). Unset ⇒ no automatic reload. |

## Usage

### 1. Inventory vars (host or group scope)

```yaml
# Enable the prometheus plugin for the "prometheus0" container.
podman_container_plugin_prometheus:
  - "prometheus0"

# Tell the role which container to SIGHUP on config change.
prometheus_containername: "prometheus0"

# Prometheus scrapes.
prometheus_scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets:
          - "localhost:9090"
  - job_name: "node"
    static_configs:
      - targets:
          - "host1.libcom.de:9100"
          - "host2.libcom.de:9100"
  - job_name: "blackbox"
    metrics_path: /probe
    params:
      module:
        - http_2xx
    static_configs:
      - targets:
          - "https://example.com"
    relabel_configs:
      - source_labels: ["__address__"]
        target_label: "__param_target"
      - source_labels: ["__param_target"]
        target_label: "instance"
      - target_label: "__address__"
        replacement: "blackbox-exporter0:9115"

# Recording + alerting rules. Each key becomes <key>.rules.yml.
prometheus_rules:
  node_alerts:
    - name: node.rules
      rules:
        - alert: NodeDown
          expr: 'up{job="node"} == 0'
          for: "5m"
          labels:
            severity: page
          annotations:
            summary: "Node {{ $labels.instance }} is down"
            description: "Prometheus has failed to scrape {{ $labels.instance }} for more than 5 minutes."

# Optional: forward alerts to an alertmanager (configured elsewhere).
prometheus_alertmanagers:
  - static_configs:
      - targets:
          - "alertmanager0:9093"

# External label identifying this instance.
prometheus_external_labels:
  monitor: "prod"
  replica: "0"
```

### 2. Container definition (consumed by `ansible_podman`)

Bind-mount the config, rules and data directories into the container. The
official image expects the config at `/etc/prometheus/prometheus.yml`, rule
files relative to `/etc/prometheus/`, and the TSDB at `/prometheus`. If you use
`prometheus_rules`, the rules mount is **required** — without it prometheus
cannot see the rendered rule files.

```yaml
podman_containers:
  - name: prometheus0
    state: started
    network: podmannetGUA
    image: docker.io/prom/prometheus:latest
    volume:
      - "/mnt/cntr/unsynced/prometheus/0/etc/:/etc/prometheus/"
      - "/mnt/cntr/unsynced/prometheus/0/etc/rules/:/etc/prometheus/rules/"
      - "/mnt/cntr/unsynced/prometheus/0/data/:/prometheus/"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--storage.tsdb.retention.time=30d"
      - "--web.enable-lifecycle"
    ports:
      - "9090:9090"
```

If you mount the rules directory at a different container-internal path, adjust
`prometheus_rules_glob` accordingly (e.g. `"custom-rules/*.yml"`).

`--web.enable-lifecycle` enables the HTTP `/-/reload` endpoint as an alternative
reload method; SIGHUP (used by the handler) works regardless of that flag.

### 3. Invoke via the podman role

Running the `ansible_podman` role with the plugin enabled causes it to call
this role automatically — no need to invoke `ansible_prometheus` directly:

```bash
ansible-playbook playbooks/podman.yml -l prom0.example.com \
  -e podman_limited_containers=prometheus0
```

With `podman_limited_containers` unset, the podman role processes all defined
containers including `prometheus0`.

## Notes

- The role creates the config, rules and data directories itself (defensively),
  in addition to the parent-directory logic in `ansible_podman`.
- Because config is rendered *before* the container starts, no second plugin
  pass is needed (unlike the psql plugin, which waits for an empty data dir).
- Alertmanager is out of scope; point `prometheus_alertmanagers` at a
  separately-managed alertmanager container.
