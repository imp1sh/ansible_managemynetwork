# imp1sh.ansible_managemynetwork.ansible_opensearch

Renders OpenSearch server configuration — `opensearch.yml` — plus the data directory onto host-side bind-mount paths consumed by a podman container. The role is **container-only**: it performs no package installation and no service management. The container itself is declared by the caller via the [`ansible_podman`](../ansible_podman/README.md) role, which invokes this role as a plugin.

## Design

Following the collection's separation-of-duty principle, `ansible_podman` owns the container lifecycle (image, network, volumes, restarts) and `ansible_opensearch` owns the configuration files that land inside the container. The podman role renders the config *before* it starts the container, so the first boot already finds a valid `opensearch.yml`.

Settings that OpenSearch equally accepts as environment variables on the container definition (notably `OPENSEARCH_JAVA_OPTS` for JVM heap sizing) remain the caller's responsibility. This role handles the parts that must be files: `opensearch.yml` and the writable data directory.

## Variables

### Paths (host bind-mount roots)

| Variable | Default | Description |
|----------|---------|-------------|
| `opensearch_path_config` | **required** | Where `opensearch.yml` is rendered. Bind-mount into the container (typically `/usr/share/opensearch/config`). No portable default — set in host_vars. |
| `opensearch_path_data` | **required** | OpenSearch data directory (indices, shards, cluster state). Bind-mount into the container (typically `/usr/share/opensearch/data`). No portable default — set in host_vars. |
| `opensearch_file_config` | `opensearch.yml` | Main config filename. |

### Ownership / modes

| Variable | Default | Description |
|----------|---------|-------------|
| `opensearch_owner` | `1000` | Owner of rendered files and the data dir. Match the container image UID. |
| `opensearch_group` | `0` | Group of rendered files and the data dir. Match the container image GID. |
| `opensearch_mode_config` | `0640` | Mode for the `opensearch.yml` **file**. Directories are always `0750`. |
| `opensearch_mode_data` | `0750` | Mode for the data directory. |

The official `opensearchproject/opensearch` image runs as UID 1000, GID 0 by default; the defaults match. Numeric ids are used because the host usually has no `opensearch` system user. Override per image if yours differs.

### opensearch.yml content

| Variable | Default | Description |
|----------|---------|-------------|
| `opensearch_yml` | `{}` | **Primary input.** Dict of top-level OpenSearch settings, serialized to YAML verbatim. Keys become top-level YAML keys in `opensearch.yml`. Leave empty to ship a header-only file and rely on OpenSearch's compiled-in defaults plus any env vars set on the container. |

### Reload

| Variable | Default | Description |
|----------|---------|-------------|
| `opensearch_containername` | `null` | Podman container name. When set, `opensearch.yml` changes notify a handler that **restarts** the container — most opensearch.yml settings are only read at startup (OpenSearch has no SIGHUP reload for core config). Unset ⇒ no automatic restart. |

### OpenSearch Dashboards (optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `opensearch_dashboards_enabled` | `false` | Master switch for the companion Dashboards config. When true, the role renders `opensearch_dashboards.yml` into `opensearch_path_dashboards_config`. The caller declares the dashboards container in `podman_containers` and bind-mounts that file. |
| `opensearch_path_dashboards_config` | `null` (**required when enabled**) | Host directory where `opensearch_dashboards.yml` is rendered. Keep it separate from `opensearch_path_config` so the two containers don't share a config dir. |
| `opensearch_dashboards_file_config` | `opensearch_dashboards.yml` | Dashboards config filename. |
| `opensearch_dashboards_yml` | `{}` | Dict of top-level OpenSearch Dashboards settings, serialized to YAML verbatim. See usage example below. |
| `opensearch_dashboards_containername` | `null` | Dashboards container name. When set, config changes notify a handler that **restarts** that container. |

## Usage

### 1. Inventory vars (host or group scope)

```yaml
# Enable the opensearch plugin for the "opensearch0" container.
podman_container_plugin_opensearch:
  - "opensearch0"

# Tell the role which container to restart on config change.
opensearch_containername: "opensearch0"

# opensearch.yml — only the settings you want to override.
opensearch_yml:
  cluster.name: "homelab"
  node.name: "opensearch0"
  # "::" binds dual-stack (IPv6 + IPv4-mapped); prefer over 0.0.0.0 (IPv4-only).
  network.host: "::"
  discovery.type: "single-node"
  # Disable the security plugin for a quick single-node start (no TLS/auth).
  # Remove for production and configure security via certs mounted separately.
  plugins.security.disabled: true
```

### 2. Container definition (consumed by `ansible_podman`)

Bind-mount the config and data directories into the container. The official
image expects the config at `/usr/share/opensearch/config/opensearch.yml` and
the data at `/usr/share/opensearch/data`.

```yaml
podman_containers:
  - name: opensearch0
    state: started
    network: podmannetGUA
    image: docker.io/opensearchproject/opensearch:2.19.0
    volume:
      - "/mnt/cntr/unsynced/opensearch/0/config/:/usr/share/opensearch/config/"
      - "/mnt/cntr/unsynced/opensearch/0/data/:/usr/share/opensearch/data/"
    ports:
      - "9200:9200"
```

Set JVM heap via the standard env var on the container definition — this role
deliberately does not render `jvm.options`:

```yaml
    env:
      OPENSEARCH_JAVA_OPTS: "-Xms2g -Xmx2g"
```

### 3. Invoke via the podman role

Running the `ansible_podman` role with the plugin enabled causes it to call
this role automatically — no need to invoke `ansible_opensearch` directly:

```bash
ansible-playbook playbooks/podman.yml -l os0.example.com \
  -e podman_limited_containers=opensearch0
```

With `podman_limited_containers` unset, the podman role processes all defined
containers including `opensearch0`.

### 4. OpenSearch Dashboards (optional visualization frontend)

Enable the dashboards config rendering and declare a second container that
bind-mounts the rendered `opensearch_dashboards.yml`. The dashboards container
talks to the backend over the podman network — no published port or traefik
route needed for the backend when dashboards fronts it.

```yaml
# Enable dashboards config rendering.
opensearch_dashboards_enabled: true
opensearch_dashboards_containername: "opensearch-dashboards0"
opensearch_path_dashboards_config: "/mnt/cntr/unsynced/opensearch/0/dashboards-config"
opensearch_dashboards_yml:
  server.name: "opensearch.example.com"
  server.host: "::"                          # dual-stack listen
  opensearch.hosts: ["http://opensearch0:9200"]
  opensearch.ssl.verificationMode: none      # backend has no TLS

# Dashboards container — front it with traefik + lan-whitelist; the backend
# stays internal on podmannet.
podman_containers:
  - name: opensearch0                         # backend (no traefik labels)
    state: started
    network: podmannet
    image: docker.io/opensearchproject/opensearch:2.19.0
    volume:
      - "/mnt/cntr/unsynced/opensearch/0/config/opensearch.yml:/usr/share/opensearch/config/opensearch.yml"
      - "/mnt/cntr/unsynced/opensearch/0/data/:/usr/share/opensearch/data/"
    env:
      OPENSEARCH_JAVA_OPTS: "-Xms1g -Xmx1g"

  - name: opensearch-dashboards0              # frontend
    state: started
    network: podmannet
    image: docker.io/opensearchproject/opensearch-dashboards:2.19.0
    volume:
      - "/mnt/cntr/unsynced/opensearch/0/dashboards-config/opensearch_dashboards.yml:/usr/share/opensearch-dashboards/config/opensearch_dashboards.yml"
    labels:
      traefik.enable: "true"
      traefik.http.routers.os-dashboards.rule: "Host(`opensearch.example.com`)"
      traefik.http.routers.os-dashboards.entrypoints: "websecure"
      traefik.http.routers.os-dashboards.tls: "true"
      traefik.http.routers.os-dashboards.service: "os-dashboards"
      traefik.http.routers.os-dashboards.middlewares: "lan-whitelist@docker,errpages-mdw"
      traefik.http.services.os-dashboards.loadbalancer.server.port: "5601"
```

Match the dashboards image version to the backend version (both `2.19.0` here)
to avoid protocol mismatches.

## Notes

- The role creates the config and data directories itself (defensively), in
  addition to the parent-directory logic in `ansible_podman`.
- Because config is rendered *before* the container starts, no second plugin
  pass is needed (unlike the psql plugin, which waits for an empty data dir).
- The OpenSearch security plugin (TLS, auth, RBAC) manages certificates and
  internal users via files under `config/`. This role renders only
  `opensearch.yml`; certificate and `internal_users.yml` management is out of
  scope — mount those files separately or extend the role when needed.
- `discovery.type: single-node` skips the bootstrap cluster-manager election
  and is ideal for a single-instance homelab. For multi-node clusters, set
  `discovery.seed_hosts` and `cluster.initial_cluster_manager_nodes` instead.
