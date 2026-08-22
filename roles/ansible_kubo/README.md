# imp1sh.ansible_managemynetwork.ansible_kubo

Bootstraps Kubo (IPFS) nodes from scratch: initialises the IPFS repo (generating a cryptographic identity), auto-discovers peer IDs for Peering, and renders the full config. Designed as a **pre-creation plugin** of the [`ansible_podman`](../ansible_podman/README.md) role — config and repo are in place before the container starts for the first time.

Pairs naturally with [`ansible_ipfscluster`](../ansible_ipfscluster/README.md) — Kubo provides the IPFS daemon, IPFS Cluster coordinates pinning across multiple Kubo nodes.

## Three-phase workflow

| Phase | What happens |
|-------|--------------|
| **1. Init** | For each instance: create the data directory, run `ipfs init --profile=server` in a throwaway container with the real data dir mounted, generating the full IPFS repo (identity, config, blocks/, datastore/, etc.). Skipped if `config` already exists. |
| **2. Collect** | Slurp all config files, extract `Identity.PeerID` from each, build a PeerID→DNS map. |
| **3. Render** | For each instance: read the existing config (to preserve the `Identity` section), build the full config dict with per-instance overrides (Swarm addresses with DNS names, API CORS origins, Gateway domain, Peering with all other nodes), deep-merge, and render. Restarts the container if the file changed and the service is already running. |

## Variables

### Instances (primary input)

| Variable | Default | Description |
|----------|---------|-------------|
| `kubo_instances` | `[]` | List of dicts, one per Kubo node. Each requires `name`, `data_dir`, `dns_short`, `dns_full`, `gateway_domain` (see below). |
| `kubo_image` | `docker.io/ipfs/kubo:v0.43.0` | Container image used for the throwaway init container. Must match the podman container definition. |

### Instance dict keys

| Key | Required | Description |
|-----|----------|-------------|
| `name` | yes | Container name (e.g. `ipfs0`). Used for the systemd service name. |
| `data_dir` | yes | Host-side path to the IPFS repo (maps to `/data/ipfs` inside the container). E.g. `/filer0/ipfs/0/data`. |
| `dns_short` | yes | Short DNS name used in Swarm addresses (e.g. `ipfs0`). |
| `dns_full` | yes | Full DNS name used in Swarm addresses (e.g. `ipfs0.dns.podman`). |
| `gateway_domain` | yes | Domain for `Gateway.PublicGateways` (e.g. `ipfs0.lpv4.net`). |
| `api_cors_origins` | no | List of CORS origins for the API. Defaults to empty list. |

### Init profile

| Variable | Default | Description |
|----------|---------|-------------|
| `kubo_profile` | `server` | Profile applied during `ipfs init`. `server` disables MDNS and sets AddrFilters for private ranges. |

### Networking

| Variable | Default | Description |
|----------|---------|-------------|
| `kubo_api_port` | `5001` | API listen port. |
| `kubo_gateway_port` | `8080` | Gateway listen port. |
| `kubo_swarm_port` | `4001` | Swarm (libp2p) listen port. |
| `kubo_swarm_transports` | *(TCP, QUIC, WebRTC, WebTransport)* | List of swarm transport multiaddresses. `{{ kubo_swarm_port }}` placeholder is substituted at render time. |

### Peering & routing

| Variable | Default | Description |
|----------|---------|-------------|
| `kubo_peering_strict` | `true` | Enforce strict peering — refuse random swarm connections. |
| `kubo_routing_type` | `none` | DHT routing type. `none` = private cluster (relay on Peering). `auto` = public DHT. |
| `kubo_bootstrap` | `[]` | Bootstrap node multiaddresses. Empty for private clusters. |

### Discovery & NAT

| Variable | Default | Description |
|----------|---------|-------------|
| `kubo_mdns_enabled` | `false` | Enable mDNS local discovery. |
| `kubo_disable_nat_port_map` | `true` | Disable NAT port mapping (UPnP/PMP). |
| `kubo_no_announce` | *(RFC1918 + ULA ranges)* | CIDRs excluded from announcement and filtered from swarm. Matches upstream `server` profile. |

### Datastore

| Variable | Default | Description |
|----------|---------|-------------|
| `kubo_storage_max` | `10GB` | Maximum datastore size before GC triggers. |
| `kubo_storage_gc_watermark` | `90` | Percentage watermark for GC trigger. |
| `kubo_gc_period` | `1h` | Garbage collection interval. |

### File ownership & systemd

| Variable | Default | Description |
|----------|---------|-------------|
| `kubo_owner` | `1000` | UID owning the config file. Matches kubo image's `ipfs` user (uid 1000). |
| `kubo_group` | `100` | GID owning the config file. Matches kubo image's `users` group (gid 100). |
| `kubo_systemd_prefix` | `""` | Systemd service name prefix. Empty for Quadlet; `container-` for legacy. |

### Advanced overrides

| Variable | Default | Description |
|----------|---------|-------------|
| `kubo_config` | *(full upstream defaults)* | Complete config dict. Override entirely for wholesale changes. |
| `kubo_config_extra` | `{}` | Arbitrary key overrides merged recursively on top of everything else. |

## Usage

In `host_vars`:

```yaml
kubo_instances:
  - name: ipfs0
    data_dir: /filer0/ipfs/0/data
    dns_short: ipfs0
    dns_full: ipfs0.dns.podman
    gateway_domain: ipfs0.lpv4.net
    api_cors_origins:
      - "https://ipfs0-api.lpv4.net"
      - "https://ipfs0.lpv4.net"
  - name: ipfs1
    data_dir: /filer0/ipfs/1/data
    dns_short: ipfs1
    dns_full: ipfs1.dns.podman
    gateway_domain: ipfs1.lpv4.net
    api_cors_origins:
      - "https://ipfs1-api.lpv4.net"
      - "https://ipfs1.lpv4.net"
  - name: ipfs2
    data_dir: /filer0/ipfs/2/data
    dns_short: ipfs2
    dns_full: ipfs2.dns.podman
    gateway_domain: ipfs2.lpv4.net
    api_cors_origins:
      - "https://ipfs2-api.lpv4.net"
      - "https://ipfs2.lpv4.net"

podman_container_plugin_kubo:
  - ipfs0
  - ipfs1
  - ipfs2
```

## How Peering works

Each node automatically peers with all other nodes defined in `kubo_instances`. The role discovers PeerIDs from the initialised configs and builds `Peering.Peers` with both TCP and QUIC addresses. Self is excluded. Combined with `kubo_peering_strict: true` and `kubo_routing_type: none`, this creates a private mesh where nodes only talk to each other.
