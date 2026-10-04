# imp1sh.ansible\_managemynetwork.ansible\_openwrtbird2

> **Status: untested — not ready for production.** This role has not yet been
> exercised against a real OpenWrt device or an imagebuilder-produced firmware.
> Syntax/lint checks pass, but neither a live `bird -p` parse-test nor a real
> BGP peering session has been verified. Use at your own risk and report back so
> the status can be lifted.

Bird 2 — the BIRD Internet Routing Daemon — for OpenWrt. This role renders
`/etc/bird.conf` from structured variables and manages the `bird` service. It
targets Bird 2 (the `bird2` / `bird2c` packages), which has a unified IPv4/IPv6
configuration language and the modern BGP feature set needed for things like
Cilium BGP peering.

Scope of this role: **BGP, static, kernel and device** protocols, plus filters,
functions, custom tables, logging and includes. OSPF, RPKI and BFD are out of
scope for now (use `extra_options` / `openwrt_bird2_includes` to reach them).

The role is inert until `openwrt_bird2_router_id` is defined. Until then it
prints a skip message and touches nothing.

## Headline use case: present an upstream GUA prefix to a Cilium cluster

Your upstream provider delegates a Global Unicast Address (GUA) prefix to your
site. You want the OpenWrt router to originate that prefix and advertise it over
BGP to your on-prem Kubernetes cluster so Cilium can allocate
`Service type=LoadBalancer` VIPs from it. Cilium, in turn, advertises the
assigned VIPs back; the router installs them into its kernel FIB and forwards
traffic to the right nodes.

```yaml
openwrt_bird2_router_id: "192.168.1.1"

openwrt_bird2_log_targets:
  - sink: "stderr"
    level: "{ error, warning }"

openwrt_bird2_device:
  enabled: true
  scan_time: 10

# Push BGP-learned routes (Cilium VIPs) into the kernel FIB.
openwrt_bird2_kernel:
  - name: "kernel6"
    persist: true
    scan_time: 10
    ipv6:
      import: "none"
      export: "all"

# Originate the upstream-delegated GUA aggregate. Blackholing it makes the
# router a credible origin without forwarding the whole /48 into the void.
openwrt_bird2_static:
  - name: "upstream_gua"
    ipv6: {}
    routes:
      - type: "blackhole"
        prefix: "2001:db8:dead::/48"

openwrt_bird2_filters:
  - |
    filter accept_upstream_gua {
      # Announce the delegated aggregate to the cluster...
      if net = 2001:db8:dead::/48 then accept;
      # ...and accept the more-specific VIPs Cilium advertises back.
      if net ~ [ 2001:db8:dead::/48+ ] then accept;
      reject;
    }

openwrt_bird2_bgp_templates:
  - name: "K8S_PEERS"
    local_as: 65001
    hold_time: 180
    graceful_restart: true
    ipv6:
      import: "filter accept_upstream_gua"
      export: "filter accept_upstream_gua"

openwrt_bird2_bgp:
  - name: "k8s_node1"
    template: "K8S_PEERS"
    local_addr: "2001:db8:cafe::1"
    neighbor_addr: "2001:db8:cafe::11"
    neighbor_as: 65002
  - name: "k8s_node2"
    template: "K8S_PEERS"
    local_addr: "2001:db8:cafe::1"
    neighbor_addr: "2001:db8:cafe::12"
    neighbor_as: 65002
```

On the Cilium side, configure a BGP virtual router (per-node ASN 65002) peering
to `2001:db8:cafe::1` and a LoadBalancer IP pool drawn from `2001:db8:dead::/48`.
The OpenWrt router will announce the aggregate downward and learn the per-VIP
more-specifics upward.

## Activation and behaviour

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_bird2_router_id` | IPv4 | – | **Required** to activate the role. Bird's router ID (a stable IPv4). |
| `openwrt_bird2_validate` | bool | `true` | Parse-test the rendered config with `bird -p` before touching the daemon (live mode). |
| `openwrt_bird2_reload_method` | `reload`\|`restart` | `reload` | How a changed config is applied: `reload` ⇒ `birdc configure` (graceful), `restart` ⇒ init-script restart (flaps sessions). |
| `openwrt_bird2_with_luci` | bool | `false` | Also install `luci-app-bird2`. |
| `openwrt_bird2_packages` | list[str] | `["bird2","bird2c"]` | Base package list fed to `ansible_packages`. |
| `openwrt_bird2_binary` | path | `/usr/sbin/bird` | Bird daemon binary (validation, live mode). |
| `openwrt_bird2_birdc` | path | `/usr/sbin/birdc` | Bird control client (reload handler). |

## Global bird.conf settings

| Variable | Type | Description |
|---|---|---|
| `openwrt_bird2_log_targets` | list[dict] | `sink` ∈ `stderr`/`syslog`/absolute-path; optional `level` (default `all`, or a Bird class set like `{ error, warning }`). |
| `openwrt_bird2_listen` | dict | `bgp: {address, port}`, `ospf: bool`. Emits `listen bgp address <a> port <p>;` / `listen ospf yes\|no;`. |
| `openwrt_bird2_includes` | list[str] | Globs/paths emitted verbatim as `include "...";`. Pair with `openwrt_bird2_dropins`. |
| `openwrt_bird2_tables` | list[dict] | Custom routing tables: `{name, sorted}`. |
| `openwrt_bird2_prepend_lines` | list[str] | Raw lines emitted near the top of `bird.conf`. |
| `openwrt_bird2_append_lines` | list[str] | Raw lines emitted at the bottom of `bird.conf`. |
| `openwrt_bird2_dropins` | list[dict] | Extra files written to `/etc/bird.d/`: `{name, content, mode}`. |

## Protocols

Unless noted, every protocol variable is a **list of dicts** (one instance per
entry). Unknown options can always be pushed through the per-instance
`extra_options` list (emitted verbatim, one statement per entry).

### `openwrt_bird2_device` — singleton dict

`protocol device {}`. Keys: `enabled` (bool, default `true`), `scan_time`,
`extra_options`.

### `openwrt_bird2_direct` — list

| Key | Type | Description |
|---|---|---|
| `name` | str | Instance name (quoted). |
| `interface` | str \| list[str] | Interface pattern(s). |
| `check_link` | bool | `check link;` |
| `ipv4` / `ipv6` | dict | Channel block (see *Channels*). `{}` enables the channel. |
| `extra_options` | list[str] | |

### `openwrt_bird2_kernel` — list

| Key | Type | Description |
|---|---|---|
| `name` | str | Instance name. |
| `learn` | bool | Import alien kernel routes. |
| `persist` | bool | Keep routes on Bird shutdown. |
| `scan_time` | int | `scan time <n>;` |
| `kernel_table` | int | `kernel table <n>;` (policy routing). |
| `table` | str | Bind to a Bird routing table. |
| `metric` | int | Kernel route metric. |
| `device_routes` | bool | Allow exporting device routes. |
| `graceful_restart` | bool | Participate in GR recovery. |
| `ipv4` / `ipv6` | dict | Channel block. |
| `extra_options` | list[str] | |

### `openwrt_bird2_static` — list

| Key | Type | Description |
|---|---|---|
| `name` | str | Instance name. |
| `table` | str | Bird table to install routes into. |
| `ipv4` / `ipv6` | dict | Channel block (usually `{}` to enable). |
| `routes` | list[dict] | See *Routes* below. |
| `extra_options` | list[str] | |

Routes (`routes[*]`):

| Key | Type | Description |
|---|---|---|
| `type` | `route`\|`blackhole`\|`unreachable`\|`prohibit` | Default `route`. |
| `prefix` | prefix | Required. |
| `via` | str \| list[str] | Next hop(s). Required for `type: route`; forbidden otherwise. A list emits one `route ... via <nh>;` per hop (ECMP). |
| `bfd` | bool | Appends `bfd`. |
| `attributes` | list[str] | Raw attribute statements wrapped in `{ ... }`. **Not** supported together with multiple `via`. |

### `openwrt_bird2_bgp_templates` / `openwrt_bird2_bgp` — list

Templates emit `template bgp <name> { ... }`; instances emit
`protocol bgp <name> [from <template>] { ... }`. Instances inherit template
options.

| Key | Type | Description |
|---|---|---|
| `name` | str | Alphanumeric/underscore, required. |
| `template` | str | (instances only) Template to inherit via `from`. |
| `local_addr` | ip | Source address for the session. |
| `local_as` | int | Local ASN. Mandatory (on the instance or its template). |
| `neighbor_addr` | ip | Neighbor endpoint. Mutually exclusive with `neighbor_range`. |
| `neighbor_range` | prefix | Dynamic-neighbor prefix. |
| `neighbor_as` | int | Neighbor ASN. |
| `source_address` | ip | `source address <ip>;` |
| `igp_table` | str | `igp table <name>;` |
| `hold_time` / `startup_hold_time` / `keepalive_time` / `connect_delay_time` / `connect_retry_time` / `error_wait_time` / `error_forget_time` / `graceful_restart_time` / `long_lived_stale_time` | int | Timer options; the role maps the camelCase keys to Bird's space-separated names. |
| `multihop` | bool \| int | `multihop;` or `multihop <n>;`. The hop count also feeds GTSM (`ttl_security`). |
| `passive` / `direct` / `rr_client` / `rs_client` / `secondary` / `check_link` / `bfd` / `disable_after_error` / `prefer_older` / `med_metric` | bool | Matching Bird flags. |
| `rr_cluster_id` | IPv4 | `rr cluster id <ip>;` |
| `add_paths` | bool \| `rx` \| `tx` | `add paths;` (both) or directional. |
| `allow_bgp_local_pref` | bool | `allow bgp_local_pref;` |
| `allow_local_as` | bool \| int | `allow local as;` or `allow local as <n>;` |
| `graceful_restart` | bool \| `aware` | `graceful restart;` or `graceful restart aware;` |
| `long_lived_graceful_restart` | bool \| `aware` | Analogous. |
| `ttl_security` | bool | `ttl security;` (GTSM). Use with `multihop <n>`. |
| `password` | str | TCP-MD5 auth. **Sensitive — supply via ansible-vault.** |
| `disabled` | bool | `disabled;` |
| `ipv4` / `ipv6` | dict | Channel block (see *Channels*). |
| `extra_options` | list[str] | |

### Channels (`ipv4` / `ipv6` dicts)

Used inside direct/kernel/static/bgp. BGP-only options are ignored for non-BGP
protocols.

| Key | Type | Description |
|---|---|---|
| `import` | str | Verbatim RHS of `import` — e.g. `all`, `none`, `filter NAME`, `where <expr>`. |
| `export` | str | Likewise for `export`. |
| `next_hop_self` | bool | (BGP) `next hop self;` |
| `next_hop_keep` | bool | (BGP) `next hop keep;` |
| `extended_next_hop` | bool | (BGP) `extended next hop;` |
| `gateway` | `direct`\|`recursive` | (BGP) `gateway <mode>;` |
| `missing_lladdr` | `self`\|`drop`\|`ignore` | (BGP) `missing lladdr <mode>;` |
| `extra_channel_options` | list[str] | |

## Functions and filters

Bird's filter language is too rich to schema-encode, so filters and functions
are supplied as **verbatim Bird 2 code**.

`openwrt_bird2_filters` is a list where each item is either:

- a string — a complete `filter <name> { ... }` block, or
- a `{name, action}` shortcut expanding to `filter <name> { <accept|reject>; }`.

`openwrt_bird2_functions` is a list where each item is either:

- a string — a complete `function ... { ... }` block, or
- a `{name, args: [{type,name}], return_type, body}` mapping (body is the
  statement list, indented automatically).

Reference filters by name in channel `import`/`export`, e.g.
`import: "filter accept_upstream_gua"`.

## How configuration is applied

In **live mode** the role renders `/etc/bird.conf`, parse-tests it with
`bird -p`, then enables and starts the `bird` service. A changed config
notifies the reload handler which, depending on `openwrt_bird2_reload_method`,
runs `birdc configure` (default, graceful) or restarts the service. A failed
parse-test aborts the play before any reload is attempted.

## OpenWrt imagebuilder support

The role obeys the collection's imagebuilder contract. All destination paths
derive from `openwrt_bird2_deployroot` (default `/`); when
`openwrt_imagebuilder_deployroot` is published by the imagebuilder role it is
adopted automatically. Set `openwrt_bird2_runimagebuilder: true` (the
`packages_runimagebuilder` global is honoured as a fallback) to switch modes.

In imagebuilder mode the role:

- renders the identical `bird.conf` into the image's `files/etc/` tree,
- creates the `etc/rc.d/S70bird` boot-enable symlink to `../init.d/bird`,
- feeds `bird2`/`bird2c` (and `luci-app-bird2` if requested) into
  `packages_installimagebuilder`,
- performs **no** parse-test, service start or reload.

Buildhost delegation follows `_openwrt_bird2_target_host` exactly like the
other OpenWrt roles.

## Deployment internals

| Variable | Default | Description |
|---|---|---|
| `openwrt_bird2_deployroot` | `/` | Root prefix for all deploy paths. |
| `openwrt_bird2_deploypath_conf` | `<deployroot>etc` | Dir for `bird.conf`. |
| `openwrt_bird2_deployfile_conf` | `bird.conf` | Config filename. |
| `openwrt_bird2_deploypath_dropindir` | `<deployroot>etc/bird.d` | Drop-in dir. |
| `openwrt_bird2_deploypath_initd` | `<deployroot>etc/init.d` | init.d dir (reference). |
| `openwrt_bird2_deploypath_rcd` | `<deployroot>etc/rc.d` | rc.d dir for the boot symlink. |
| `openwrt_bird2_initscript` | `bird` | init script / service name. |
| `openwrt_bird2_rc_order` | `S70bird` | Boot-symlink name. |
| `openwrt_bird2_runimagebuilder` | `false` | Imagebuilder-mode switch. |

## Caveats

- **Template inheritance of `local`/`neighbor`.** Bird does not merge partial
  `local`/`neighbor` statements across template inheritance — an instance's
  statement replaces the template's. Put `local_as` (and, if shared,
  `local_addr`) in the template; if an instance overrides `local_addr`, also
  re-state `local_as` on the instance.
- **GTSM.** `ttl_security: true` enables `ttl security;`; the expected TTL is
  derived from `multihop: <n>`. For direct sessions omit `multihop`.
- **Multipath + attributes.** A static route with multiple `via` and
  `attributes` at once is rejected by `checks.yml`; use one or the other.
- **Secrets.** `password` (and any credential in `extra_options`) must be
  supplied through ansible-vault. The role never hardcodes secrets.
