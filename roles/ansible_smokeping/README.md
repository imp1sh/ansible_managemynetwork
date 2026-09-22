# imp1sh.ansible_managemynetwork.ansible_smokeping

Renders Smokeping configuration — the native `*** Section ***` config file —
onto host-side bind-mount paths consumed by a podman container. The role is
**container-only**: it performs no package installation and no service
management. The container itself is declared by the caller via the
[`ansible_podman`](../ansible_podman/README.md) role, which invokes this role
as a plugin.

## Design

Following the collection's separation-of-duty principle, `ansible_podman` owns
the container lifecycle (image, network, volumes, restarts) and
`ansible_smokeping` owns the configuration file that lands inside the
container. The podman role renders the config *before* it starts the
container, so the first boot already finds a valid config.

Unlike alertmanager (whose config IS YAML and is dumped via `to_nice_yaml`),
Smokeping speaks its own INI-like grammar: `*** Section ***` markers, a
generic `+`/`++`/… subsection tree, and whitespace-aligned tables. This role
models that grammar as a structured dict and renders it with a purpose-built
Jinja2 template. The grammar reference is
<https://oss.oetiker.ch/smokeping/doc/smokeping_config.en.html>.

## Variables

### Paths

| Variable | Default | Description |
|----------|---------|-------------|
| `smokeping_path_config` | **required** | Host directory where the config is rendered. Bind-mount into the container (commonly `/etc/smokeping`, or `/config` on linuxserver.io images). No portable default — set in host_vars. |
| `smokeping_file_config` | `config` | Config filename inside `smokeping_path_config`. Match what your container image expects (stock Debian layout calls it `config`). |

### Ownership / modes

| Variable | Default | Description |
|----------|---------|-------------|
| `smokeping_owner` | `root` | Owner of the rendered file. Match the container image UID; `root` + mode `0644` is readable by any in-container user. |
| `smokeping_group` | `root` | Group of the rendered file. |
| `smokeping_mode_config` | `0644` | Mode for the config file. |

### Configuration content

| Variable | Default | Description |
|----------|---------|-------------|
| `smokeping_config` | `{}` | **Primary input.** Dict of section name → body. Three body shapes are recognised (below). |

The renderer recognises **three body shapes**. A section may use whichever
fits; many sections combine flat scalars with subsections and/or a table.

#### 1. Flat — `key = value` lines

Used by General, Database (sans table), the top-level of Alerts, etc.:

```yaml
smokeping_config:
  General:
    owner: "Jochen Demmark"
    contact: "jochen@libcom.de"
    mailhost: "smtp.libcom.de"
    imgcache: "/var/cache/smokeping/images"
    imgurl: "/smokeping/img"
    datadir: "/var/lib/smokeping"
    piddir: "/run/smokeping"
    cgiurl: "https://smokeping.example.com/smokeping.cgi"
    smokemail: "/etc/smokeping/smokemail"
    concurrentprobes: "yes"
    offset: "random"
  Database:
    step: 300
    pings: 20
  Alerts:
    to: "jochen@libcom.de"
    from: "smokeping@libcom.de"
```

#### 2. Hierarchical — `+`/`++`/… subsections

Generic: works for **any** subsection-bearing section — Probes, Targets,
Presentation (`+overview`/`+detail`/`+charts`/`+multihost`), Alerts
(per-alert `+` definitions), Slaves, Authentication. A section or entry may
carry top-level scalar props **plus** an `entries` list of named subsections.
Each entry is a dict with a `name` (shown after the `+`), further scalar
props, an optional `table`/`table_header` (shape 3), and an optional nested
`entries` list. Nesting depth drives the `+`/`++`/… count:

```yaml
smokeping_config:
  Probes:
    entries:
      - name: FPing
        binary: "/usr/bin/fping"
        entries:
          - name: FPingLarge
            packetsize: 1000
            step: 300
          - name: FPingSmall
            packetsize: 64
            step: 30
  Targets:
    probe: FPing
    menu: Top
    title: Network Latency Graphs
    remark: "Welcome to the SmokePing records."
    alerts: ["bigloss", "somedown"]
    entries:
      - name: Local
        menu: Local
        title: Local network
        entries:
          - name: Router
            menu: Router
            title: Home router
            host: "10.10.0.1"
      - name: Internet
        menu: Internet
        title: Internet hosts
        entries:
          - name: GoogleDNS
            menu: "8.8.8.8"
            title: Google Public DNS
            host: "8.8.8.8"
```

#### 3. Table — whitespace-aligned columns

Attached to a section body **or** an entry via `table` (list of rows; each row
a list of cells) plus optional `table_header` (list of column names rendered
as a `# ` comment row). Columns auto-align to the widest cell; cells
containing whitespace or double-quotes are auto-double-quoted (embedded
quotes backslash-escaped). Used by the Database RRA table, the Presentation
`+detail` resolution table, and `++loss_colors` / `++uptime_colors`:

```yaml
smokeping_config:
  Database:
    step: 300
    pings: 20
    table_header: ["cons", "xff", "steps", "rows"]
    table:
      - ["AVERAGE", 0.5, 1, 1008]
      - ["AVERAGE", 0.5, 12, 4320]
      - ["MIN", 0.5, 12, 4320]
      - ["MAX", 0.5, 12, 4320]
  Presentation:
    template: "/etc/smokeping/basepage.html"
    entries:
      - name: detail
        width: 600
        height: 200
        table:
          - ["Last 3 Hours", "3h"]
          - ["Last 30 Hours", "30h"]
          - ["Last 10 Days", "10d"]
          - ["Last 400 Days", "400d"]
        entries:
          - name: loss_colors
            table_header: ["Loss", "Color", "Legend"]
            table:
              - [1, "00ff00", "<1"]
              - [3, "0000ff", "<3"]
              - [1000, "ff0000", ">=3"]
          - name: uptime_colors
            table_header: ["Uptime", "Color", "Legend"]
            table:
              - [3600, "00ff00", "<1h"]
              - [86400, "0000ff", "<1d"]
```

#### Value formatting & ordering

Scalar props:
- `null` values **omit** the line (lets a caller null out a default).
- Booleans render lowercase (`true`/`false`).
- Lists render space-joined (for multi-value directives like `alerts`).
- Everything else renders as its string form, unquoted.

Table cells:
- A cell is auto-double-quoted iff it is a string containing whitespace or a
  double-quote; embedded quotes are escaped with backslash. Numeric and
  whitespace-free cells render bare.

Ordering is preserved: dict keys in insertion order, `entries` in list order,
`table` rows in list order — so the caller controls the on-disk sequence.

#### Escape hatch

A section body may alternatively be a plain string, written verbatim (split on
newlines) under the section header. Use this only for fragments the structured
renderer cannot express (e.g. `@include` / `@define` directives, or hand-tuned
layouts).

### Reload mechanism

| Variable | Default | Description |
|----------|---------|-------------|
| `smokeping_containername` | `null` | Name of the podman container running smokeping. When set, config changes notify a handler that restarts the container (smokeping reads its config only at startup). Under Quadlet the unit is `<name>`; under the legacy `podman generate systemd` path it is `container-<name>` — picked automatically from `podman_use_quadlet`. |

## Example

Enable the plugin and point it at the container, then declare the container
and the smokeping vars:

```yaml
podman_container_plugin_smokeping:
  - "smokeping0"
smokeping_containername: "smokeping0"
smokeping_path_config: "/mnt/cntr/unsynced/smokeping/0/etc"

podman_containers:
  - name: smokeping0
    state: started
    network: podmannetGUA
    image: lscr.io/linuxserver/smokeping:latest
    volume:
      - "/mnt/cntr/unsynced/smokeping/0/etc/:/config/"
      - "/mnt/cntr/unsynced/smokeping/0/data/:/data/"
    ports:
      - "8084:80"

smokeping_config:
  General:
    owner: "Jochen Demmer"
    contact: "jochen@libcom.de"
    imgcache: "/var/cache/smokeping/images"
    imgurl: "/smokeping/img"
    datadir: "/data"
    piddir: "/run/smokeping"
    cgiurl: "https://smokeping.example.com/smokeping.cgi"
  Database:
    step: 300
    pings: 20
  Probes:
    entries:
      - name: FPing
        binary: "/usr/bin/fping"
  Targets:
    probe: FPing
    menu: Top
    title: Network Latency Graphs
    entries:
      - name: Router
        menu: Router
        title: Home router
        host: "10.10.0.1"
```

See the `ansible_podman` README's **Plugins** section for how plugins are
enabled via `podman_container_plugin_<name>`.
