# imp1sh.ansible_managemynetwork.ansible_grafana

Renders Grafana configuration — `grafana.ini` plus datasource and dashboard-provider provisioning files — onto host-side bind-mount paths consumed by a podman container. The role is **container-only**: it performs no package installation and no service management. The container itself is declared by the caller via the [`ansible_podman`](../ansible_podman/README.md) role, which invokes this role as a plugin.

## Design

Following the collection's separation-of-duty principle, `ansible_podman` owns the container lifecycle (image, network, volumes, restarts) and `ansible_grafana` owns the configuration files that land inside the container. The podman role renders the config *before* it starts the container, so the first boot already finds a valid `grafana.ini` and provisioning tree.

Settings that Grafana equally accepts as `GF_*` environment variables on the container definition remain the caller's responsibility. This role handles the parts that must be files: `grafana.ini` and the provisioning directories (`datasources/`, `dashboards/`).

## Variables

### Paths (host bind-mount roots)

| Variable | Default | Description |
|----------|---------|-------------|
| `grafana_path_config` | **required** | Where `grafana.ini` is rendered. Bind-mount into the container (typically `/etc/grafana`). No portable default — set in host_vars. |
| `grafana_path_provisioning` | `{{ grafana_path_config }}/provisioning` | Root of the provisioning tree. Bind-mount into the container (typically `/etc/grafana/provisioning`). |
| `grafana_path_datasources` | `{{ grafana_path_provisioning }}/datasources` | Where datasource provisioning files are rendered. Bind-mount into the container (typically `/etc/grafana/provisioning/datasources`). |
| `grafana_path_dashboards` | `{{ grafana_path_provisioning }}/dashboards` | Where dashboard-provider provisioning files are rendered. Bind-mount into the container (typically `/etc/grafana/provisioning/dashboards`). |
| `grafana_path_data` | **required** | Grafana state (sqlite database, sessions, plugins). Bind-mount into the container (typically `/var/lib/grafana`). No portable default — set in host_vars. |
| `grafana_file_config` | `grafana.ini` | Main config filename. |

### Ownership / modes

| Variable | Default | Description |
|----------|---------|-------------|
| `grafana_owner` | `472` | Owner of rendered files and the data dir. Match the container image UID. |
| `grafana_group` | `0` | Group of rendered files and the data dir. Match the container image GID. |
| `grafana_mode_config` | `0644` | Mode for `grafana.ini`. |
| `grafana_mode_provisioning` | `0644` | Mode for provisioning files. |
| `grafana_mode_data` | `0755` | Mode for the data directory. |

The official `grafana/grafana` image runs as UID 472, GID 0 by default; the defaults match. Numeric ids are used because the host usually has no `grafana` system user. Override per image if yours differs.

### grafana.ini content

| Variable | Default | Description |
|----------|---------|-------------|
| `grafana_ini` | `{}` | **Primary input.** Dict of INI section name → `{key: value}`. Each top-level key becomes an `[section]` header; nested pairs become `key = value` lines. Section names may contain dots (e.g. `auth.anonymous`). Boolean values are rendered lowercase; `null` omits the line. Anything not listed falls back to grafana's compiled-in defaults (plus any `GF_*` env vars set on the container). |

### Provisioning

| Variable | Default | Description |
|----------|---------|-------------|
| `grafana_datasources` | `{}` | Dict keyed by filename stem; each value is a list of datasource objects as grafana's provisioning schema expects under `datasources:`. Rendered as `<stem>.yml` in `grafana_path_datasources`. |
| `grafana_dashboard_providers` | `{}` | Dict keyed by filename stem; each value is a list of provider objects as grafana's provisioning schema expects under `providers:`. Rendered as `<stem>.yml` in `grafana_path_dashboards`. Point each provider's `options.path` at a directory mounted into the container; the role can populate that directory from git (see Dashboards below). |

### Dashboards from git

| Variable | Default | Description |
|----------|---------|-------------|
| `grafana_dashboards_repo` | `null` | Git repository holding dashboard JSON files. When set, the role clones/updates it to `grafana_dashboards_dest` and notifies the provisioning-reload handler so grafana picks up changes on SIGHUP. Leave unset to skip git sync. |
| `grafana_dashboards_dest` | `{{ grafana_path_data }}/dashboards` | Host directory where dashboard JSONs are synced. Defaults to a `dashboards` subdir under `grafana_path_data`, which the typical `/var/lib/grafana` bind-mount exposes inside the container at `/var/lib/grafana/dashboards` — match this to the `options.path` of your `grafana_dashboard_providers` entry. |
| `grafana_dashboards_version` | `null` | Branch/tag/commit to check out. Leave unset to track the repository's default branch (`HEAD`). |
| `grafana_dashboards_clone_depth` | `1` | Shallow-clone depth. `1` fetches only the latest commit for speed; `0` for a full-history clone. |
| `grafana_dashboards_git_username` | `null` | Username for HTTP(S) Basic Auth on private repos. Set together with `grafana_dashboards_git_password` (both or neither). Ignored for SSH URLs. |
| `grafana_dashboards_git_password` | `null` | Password / read-only deploy token / personal-access-token for HTTP(S) Basic Auth. **Vault this.** The role strips credentials out of the clone's `.git/config` after each sync so they do not rest on disk between runs. |

### Dashboards from the grafana.com hub

| Variable | Default | Description |
|----------|---------|-------------|
| `grafana_dashboards_from_hub` | `[]` | List of community dashboards to pull from grafana.com by numeric ID. Each entry is a dict: `id` (positive int, required), `revision` (int or the literal `latest`, optional; default `latest`), `filename` (basename without `.json`, optional; defaults to the id). Files land in `grafana_dashboards_hub_dest`; pair with a `grafana_dashboard_providers` entry whose `options.path` points at the in-container equivalent. |
| `grafana_dashboards_hub_dest` | `{{ grafana_path_data }}/dashboards-hub` | Host directory where hub-downloaded dashboards are stored. Kept separate from `grafana_dashboards_dest` so the git and hub flows don't collide. |
| `grafana_dashboards_hub_api` | `https://grafana.com/api/dashboards` | Base URL of the grafana.com public dashboard API. Override only for a private mirror exposing the same shape. |

### Reload

| Variable | Default | Description |
|----------|---------|-------------|
| `grafana_containername` | `null` | Podman container name. When set, `grafana.ini` changes notify a handler that **restarts** the container (most ini settings are only read at startup), while provisioning file changes notify a handler that sends **SIGHUP** via `podman exec <name> kill -HUP 1` (grafana hot-reloads provisioning on SIGHUP). Unset ⇒ no automatic reload/restart. |

## Usage

### 1. Inventory vars (host or group scope)

```yaml
# Enable the grafana plugin for the "grafana0" container.
podman_container_plugin_grafana:
  - "grafana0"

# Tell the role which container to restart/SIGHUP on config change.
grafana_containername: "grafana0"

# grafana.ini — only the sections you want to override.
grafana_ini:
  server:
    http_port: "3000"
    domain: "grafana.example.com"
    root_url: "%(protocol)s://%(domain)s/"
  security:
    admin_user: "admin"
    admin_password: "changeme"
    disable_gravatar: true
  auth.anonymous:
    enabled: true
    org_role: "Viewer"
  database:
    type: "postgres"
    host: "psql0:5432"
    name: "grafana"
    user: "grafana"
    password: "secret"
  smtp:
    enabled: true
    host: "localhost:25"
    from_address: "grafana@example.com"

# Datasource provisioning. Each key becomes <key>.yml.
grafana_datasources:
  prometheus:
    - name: Prometheus
      type: prometheus
      access: proxy
      url: http://prometheus0:9090
      isDefault: true
    - name: VictoriaMetrics
      type: prometheus
      access: proxy
      url: http://victoria0:8428

# Dashboard provider provisioning. Point `options.path` at a directory mounted
# into the container, then drop dashboard JSON files there.
grafana_dashboard_providers:
  default:
    - name: default
      orgId: 1
      folder: ""
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards
```

### 2. Container definition (consumed by `ansible_podman`)

Bind-mount the config, provisioning and data directories into the container. The
official image expects the config at `/etc/grafana/grafana.ini`, provisioning
under `/etc/grafana/provisioning/`, and the state at `/var/lib/grafana`.

```yaml
podman_containers:
  - name: grafana0
    state: started
    network: podmannetGUA
    image: docker.io/grafana/grafana:13.0.6
    volume:
      - "/mnt/cntr/unsynced/grafana/0/etc/grafana.ini:/etc/grafana/grafana.ini"
      - "/mnt/cntr/unsynced/grafana/0/etc/provisioning/:/etc/grafana/provisioning/"
      - "/mnt/cntr/unsynced/grafana/0/data/:/var/lib/grafana/"
    ports:
      - "3000:3000"
```

If you only want to provision datasources/dashboards and leave `grafana.ini` at
the image defaults, set `grafana_ini: {}` (an empty dict renders a minimal
header-only file; grafana fills in compiled-in defaults for everything else).

### 3. Invoke via the podman role

Running the `ansible_podman` role with the plugin enabled causes it to call
this role automatically — no need to invoke `ansible_grafana` directly:

```bash
ansible-playbook playbooks/podman.yml -l grafana0.example.com \
  -e podman_limited_containers=grafana0
```

With `podman_limited_containers` unset, the podman role processes all defined
containers including `grafana0`.

### 4. Dashboards from a git repository

Set `grafana_dashboards_repo` and the role clones/updates it into
`grafana_dashboards_dest` (default `{{ grafana_path_data }}/dashboards`), then
notifies the SIGHUP handler so grafana hot-reloads. No extra container volume is
needed as long as `grafana_dashboards_dest` lies under a path already mounted
into the container — the default puts it under `grafana_path_data`, which the
typical `/var/lib/grafana` bind-mount exposes at `/var/lib/grafana/dashboards`.

```yaml
# Provider that tells grafana where to look for dashboard JSONs.
grafana_dashboard_providers:
  default:
    - name: default
      orgId: 1
      folder: ""
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards

# Repository holding the dashboard JSON files. The role syncs this to
# grafana_dashboards_dest (here left at the default
# {{ grafana_path_data }}/dashboards), which the /var/lib/grafana mount
# exposes at /var/lib/grafana/dashboards — matching the provider path above.
grafana_dashboards_repo: "git@git.example.net:jochen/grafana-dashboards.git"
# grafana_dashboards_version: "main"   # optional: pin a branch/tag
```

Private repositories rely on the target host's normal git/SSH credentials (deploy
key, ssh-agent forwarding, etc.) — the role uses `ansible.builtin.git` and adds
no authentication of its own. Files land root-owned but world-readable (0644),
which is all grafana needs since it only reads the JSONs.

#### Private repos over HTTP(S) with username/password

When you can't distribute SSH deploy keys to every target, use HTTP(S) Basic
Auth with a read-only, repo-scoped deploy token as the password. Set both
credentials (the password is a secret — vault it):

```yaml
grafana_dashboards_repo: "https://git.example.net/jochen/grafana-dashboards.git"
grafana_dashboards_git_username: "deploy-token-name"
grafana_dashboards_git_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...
```

The role passes them to `ansible.builtin.git` for the fetch, then resets
`remote.origin.url` back to the clean repo string so the credentials do not
linger in the clone's `.git/config` on the target between runs. Characters in
the password that are reserved in a URL userinfo segment (notably `@`, `:`, `/`)
may need percent-encoding; prefer a token composed of URL-safe characters, or
test with the actual value.

### 5. Dashboards from the grafana.com hub

Community dashboards published on grafana.com can be pulled straight by their
numeric ID — no API key, no local checkout. Each entry resolves a revision
(either a pinned integer or `latest`, which queries the hub metadata API on
every run) and downloads the JSON into `grafana_dashboards_hub_dest`. Wire a
`grafana_dashboard_providers` entry at the matching in-container path so grafana
discovers the files on SIGHUP.

```yaml
# Second provider pointed at the hub download dir. The default
# grafana_dashboards_hub_dest lives under grafana_path_data, so the typical
# /var/lib/grafana bind-mount exposes it at /var/lib/grafana/dashboards-hub.
grafana_dashboard_providers:
  hub:
    - name: hub
      orgId: 1
      folder: "Community"
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards-hub

# Pull the Node Exporter Full dashboard (always latest) and a pinned revision
# of the Redis dashboard.
grafana_dashboards_from_hub:
  - id: 1860            # Node Exporter Full
    filename: node_exporter_full
  - id: 11074           # Redis Dashboard
    revision: 1
    filename: redis
```

The `latest` resolver reads the newest published revision from
`GET /api/dashboards/<id>`, then downloads
`/api/dashboards/<id>/revisions/<rev>/download`. Pin `revision` to an integer
for reproducible pulls and faster runs (no metadata lookup on each play).

## Notes

- The role creates the config, provisioning and data directories itself
  (defensively), in addition to the parent-directory logic in `ansible_podman`.
- Because config is rendered *before* the container starts, no second plugin
  pass is needed (unlike the psql plugin, which waits for an empty data dir).
- `grafana.ini` is INI, not YAML. The role serialises the `grafana_ini` dict
  into `[section]` / `key = value` form; it does not validate individual keys
  against grafana's schema (grafana does that at startup and logs warnings).
- Alerting/notification/RBAC provisioning is out of scope for now; add further
  `grafana_*` dicts to extend the role when needed.
