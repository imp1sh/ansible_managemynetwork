# imp1sh.ansible_managemynetwork.ansible_traefik

Renders Traefik **static configuration** (`traefik.yml`), **dynamic file-provider configuration**, and initialises the **ACME certificate store** (`acme.json`) onto host-side bind-mount paths consumed by a podman container. The role is **container-only**: it performs no package installation and no service management. The container itself is declared by the caller via the [`ansible_podman`](../ansible_podman/README.md) role, which invokes this role as a plugin.

## Design

Traefik can be configured via CLI flags, env vars, labels, or files. This role handles the parts that **must be files**:

- **Static config** (`traefik.yml`) — entrypoints, providers, certificate resolvers, API, logging. Changes require a container restart (traefik cannot reload static config on SIGHUP).
- **Dynamic config** (file provider) — routers, services, middlewords, TLS, redirects. Traefik watches the directory and hot-reloads on file changes — no restart needed.
- **`acme.json`** — Let's Encrypt certificate store. Created with mode `0600` if absent; **never overwritten** if it already exists (holds irreplaceable certificates).

Env vars and labels on the container definition are the caller's responsibility — set them in your `podman_containers` entry. This role does not duplicate what the container layer already handles.

## Variables

### Paths (host bind-mount roots)

| Variable | Default | Description |
|----------|---------|-------------|
| `traefik_path_config` | `/mnt/cntr/unsynced/traefik/0/etc` | Where `traefik.yml` is rendered. Bind-mount into the container (typically `/etc/traefik`). |
| `traefik_path_dynamic` | `{{ traefik_path_config }}/dynamic` | Where dynamic file-provider configs are rendered. Bind-mount into the container (typically `/etc/traefik/dynamic`). |
| `traefik_path_acme` | `{{ traefik_path_config }}/acme.json` | Path to `acme.json` (**a file**, not a dir). Bind-mount into the container. Created `0600` if absent; never overwritten. |
| `traefik_file_config` | `traefik.yml` | Static config filename. |

### Ownership / modes

| Variable | Default | Description |
|----------|---------|-------------|
| `traefik_owner` | `root` | Owner of rendered files. Match the container image UID. |
| `traefik_group` | `root` | Group of rendered files. Match the container image GID. |
| `traefik_mode_config` | `0644` | Mode for `traefik.yml` and dynamic config files. |
| `traefik_mode_dynamic` | `0644` | Mode for dynamic config files. |
| `traefik_mode_acme` | `0600` | Mode for `acme.json`. **Must be `0600`** — traefik refuses to start otherwise. |

The official `traefik` image runs as root by default (needs to bind `:80`/`:443`). Override per image if yours runs as a non-root user.

### Static configuration (traefik.yml)

Each variable maps to the corresponding top-level key in traefik's static config. Leave at the default (empty/null) to omit the section.

| Variable | Default | Description |
|----------|---------|-------------|
| `traefik_entrypoints` | `{}` | Dict of entrypoint name → config (address, http.tls, etc.). |
| `traefik_providers` | `{}` | Provider config (docker, file, etc.). |
| `traefik_certificates_resolvers` | `{}` | Dict of resolver name → ACME config. |
| `traefik_api` | `null` | Dashboard/API config. Omitted when `null`. |
| `traefik_log` | `null` | Log level/format. Omitted when `null`. |
| `traefik_access_log` | `null` | Access log config. Omitted when `null`. |
| `traefik_ping` | `null` | Healthcheck endpoint config. Omitted when `null`. |
| `traefik_experimental` | `null` | Experimental features. Omitted when `null`. |

### Dynamic configuration (file provider)

| Variable | Default | Description |
|----------|---------|-------------|
| `traefik_dynamic_config` | `{}` | Dict keyed by filename stem; each value is a dynamic-config dict (routers, services, middlewares, tls, http, tcp, udp). Rendered as `<stem>.yml` in `traefik_path_dynamic`. |

### Reload

| Variable | Default | Description |
|----------|---------|-------------|
| `traefik_containername` | `null` | Podman container name. When set, static-config changes notify a handler that restarts the container via systemd (respects `podman_use_quadlet`). Dynamic config files are hot-reloaded by traefik's file watcher and need no handler. |

## Usage

### 1. Inventory vars (host or group scope)

```yaml
# Enable the traefik plugin for the "traefik0" container.
podman_container_plugin_traefik:
  - "traefik0"

# Tell the role which container to restart on static-config change.
traefik_containername: "traefik0"

# Entrypoints.
traefik_entrypoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

# Providers — docker (podman socket) + file (dynamic config).
traefik_providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    directory: "/etc/traefik/dynamic"
    watch: true

# Let's Encrypt.
traefik_certificates_resolvers:
  letsencrypt:
    acme:
      email: "admin@example.com"
      storage: "/etc/traefik/acme.json"
      httpChallenge:
        entryPoint: web

# Dashboard (protect in production!).
traefik_api:
  dashboard: true

# Dynamic config: HTTP-to-HTTPS redirect.
traefik_dynamic_config:
  redirect:
    http:
      routers:
        router0:
          rule: "Host(`example.com`)"
          middlewares:
            - redirect-to-https
          service: noop
      middlewares:
        redirect-to-https:
          redirectScheme:
            scheme: https
```

### 2. Container definition (consumed by `ansible_podman`)

Bind-mount the config directory and the podman socket. The official image
expects the static config at `/etc/traefik/traefik.yml` and reads `acme.json`
from the path you configure in `certificatesResolvers`.

```yaml
podman_containers:
  - name: traefik0
    state: started
    network: podmannet
    image: docker.io/traefik:v3.7.10
    volume:
      - "/run/podman/podman.sock:/var/run/docker.sock"
      - "/mnt/cntr/unsynced/traefik/0/etc/:/etc/traefik/"
      - "/mnt/cntr/unsynced/traefik/0/etc/dynamic/:/etc/traefik/dynamic/"
    ports:
      - "80:80"
      - "443:443"
    env:
      TRAEFIK_API_DASHBOARD: "true"
```

On Fedora / SELinux-enforcing hosts where the container needs to access the
podman socket, see the [Fedora / SELinux](../ansible_podman/README.md#fedora--selinux)
section of the ansible_podman README — the podman role auto-detects the socket
mount and emits `SecurityLabelType=container_runtime_t` under Quadlet.

### 3. Invoke via the podman role

Running the `ansible_podman` role with the plugin enabled causes it to call
this role automatically — no need to invoke `ansible_traefik` directly:

```bash
ansible-playbook playbooks/podman.yml -l proxy0.example.com \
  -e podman_limited_containers=traefik0
```

## Notes

- **`acme.json` safety**: the role uses `force: false` on the copy task, so an
  existing `acme.json` is never touched — only created (empty, `0600`) if
  absent. Your Let's Encrypt certificates survive every Ansible run.
- **Static vs dynamic reload**: static config changes trigger a container
  restart via the handler. Dynamic config changes are picked up by traefik's
  file watcher (ensure `watch: true` on the file provider) — no restart needed.
- Ordering: the podman plugin chooser runs *before* container creation, so
  `traefik.yml` and `acme.json` are in place on first boot.
