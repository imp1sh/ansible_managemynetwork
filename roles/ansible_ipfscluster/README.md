# imp1sh.ansible_managemynetwork.ansible_ipfscluster

Bootstraps IPFS Cluster peers from scratch: generates cryptographic identities, auto-discovers peer IDs for the trusted-peers list, and renders `service.json` with all configurable sections. Designed as a **pre-creation plugin** of the [`ansible_podman`](../ansible_podman/README.md) role — config files are in place before the container starts for the first time.

## Three-phase workflow

| Phase | What happens |
|-------|--------------|
| **1. Init** | For each instance: create the data directory, run `ipfs-cluster-service init` in a throwaway container (temp dir) to generate `identity.json`, copy it to the data dir. Skipped if `identity.json` already exists. |
| **2. Collect** | Slurp all `identity.json` files, extract peer IDs (`id` field), build the `trusted_peers` list. If `ipfscluster_trusted_peers` is set explicitly, it takes precedence. |
| **3. Render** | For each instance: deep-merge the base config dict with per-instance overrides (peername, ipfs\_node multiaddress, ports) and shared overrides (secret, cluster\_name, trusted\_peers, replication factor), then render `service.json` via template. Restarts the container if the file changed and the service is already running. |

## Variables

### Instances (primary input)

| Variable | Default | Description |
|----------|---------|-------------|
| `ipfscluster_instances` | `[]` | List of dicts, one per cluster peer. Each requires `name`, `data_dir`, `ipfs_node` (see below). |
| `ipfscluster_image` | `docker.io/ipfs/ipfs-cluster:v1.1.6` | Container image used for the throwaway init container. Must match the image in the podman container definition. |

### Instance dict keys

| Key | Required | Description |
|-----|----------|-------------|
| `name` | yes | Container name (e.g. `ipfscluster0`). Used for the systemd service name. |
| `data_dir` | yes | Host-side path for `service.json` + `identity.json` (e.g. `/filer0/ipfs/cluster0`). |
| `ipfs_node` | yes | DNS name of the corresponding kubo container, resolvable inside the podman network (e.g. `ipfs0.dns.podman`). |
| `peername` | no | Human-readable peer name. Defaults to `name`. |

### Shared cluster config

| Variable | Default | Description |
|----------|---------|-------------|
| `ipfscluster_secret` | `""` (**required**) | 32-byte hex-encoded cluster secret (64 chars). Vault-encrypt in host\_vars. |
| `ipfscluster_cluster_name` | `ipfs-cluster` | CRDT cluster name. Peers with the same name + secret form a cluster. |
| `ipfscluster_trusted_peers` | `[]` | Trusted peer IDs. If empty, auto-discovered from `identity.json` files + `ipfscluster_remote_peers`. When set explicitly, takes full precedence over both. |
| `ipfscluster_remote_peers` | `[]` | Peers on **other hosts** — list of `{id, address}` dicts. Merged into `trusted_peers` and `cluster.peer_addresses`. See [Cross-host clustering](#cross-host-clustering). |
| `ipfscluster_replication_factor_min` | `-1` | Minimum replicas per pin (-1 = all peers). |
| `ipfscluster_replication_factor_max` | `-1` | Maximum replicas per pin (-1 = all peers). |

### Networking

| Variable | Default | Description |
|----------|---------|-------------|
| `ipfscluster_ipfs_api_port` | `5001` | Kubo daemon API port. |
| `ipfscluster_ipfs_node_addr_type` | `dns6` | Multiaddress type for kubo DNS resolution (`dns4`, `dns6`, `dns`). |
| `ipfscluster_restapi_port` | `9094` | REST API listen port. |
| `ipfscluster_proxy_port` | `9095` | IPFS Proxy listen port. |
| `ipfscluster_swarm_port` | `9096` | Cluster swarm (libp2p) listen port. |
| `ipfscluster_pinning_port` | `9097` | Pinning Service API listen port. |
| `ipfscluster_metrics_port` | `8888` | Prometheus metrics listen port. |

### File ownership & systemd

| Variable | Default | Description |
|----------|---------|-------------|
| `ipfscluster_owner` | `root` | Owner of `service.json` and `identity.json`. |
| `ipfscluster_group` | `root` | Group of `service.json` and `identity.json`. |
| `ipfscluster_systemd_prefix` | `""` | Systemd service name prefix. Empty for Quadlet; `container-` for legacy. |

### Advanced overrides

| Variable | Default | Description |
|----------|---------|-------------|
| `ipfscluster_service_config` | *(full upstream defaults)* | Complete `service.json` config dict. Override entirely for wholesale changes. |
| `ipfscluster_service_config_extra` | `{}` | Arbitrary key overrides merged recursively on top of everything else. Useful for tweaking obscure settings without copying the full config. |

## Usage

In `host_vars`:

```yaml
ipfscluster_secret: !vault |
    $ANSIBLE_VAULT;1.1;AES256
    ...

ipfscluster_instances:
  - name: ipfscluster0
    data_dir: /filer0/ipfs/cluster0
    peername: cluster0
    ipfs_node: ipfs0.dns.podman
  - name: ipfscluster1
    data_dir: /filer0/ipfs/cluster1
    peername: cluster1
    ipfs_node: ipfs1.dns.podman
  - name: ipfscluster2
    data_dir: /filer0/ipfs/cluster2
    peername: cluster2
    ipfs_node: ipfs2.dns.podman

podman_container_plugin_ipfscluster:
  - ipfscluster0
  - ipfscluster1
  - ipfscluster2
```

## How it integrates with ansible\_podman

The role is registered as a **pre-creation plugin** in `ansible_podman/tasks/2plugin_chooser.yml`. The podman role invokes it before creating containers, so `service.json` and `identity.json` are already in place on first boot. On subsequent runs, if `service.json` content changes, the role restarts the affected container(s).

### Security of the private cluster

The cluster stays private through cryptographic controls, not network ACLs:

- **`ipfscluster_secret`** (libp2p PSK) — all cluster swarm connections require this 32-byte secret at the Noise handshake. Without it, connections are rejected before any cluster protocol exchange. An attacker who reaches port 9096 cannot join or disrupt the cluster.
- **`trusted_peers`** — only listed PeerIDs can participate in CRDT consensus. Unknown peers are ignored even if they somehow connect.
- **`pin_only_on_trusted_peers: true`** — pins are only placed on trusted peers.

This means the cluster swarm port (9096) can be safely **published on a public IP** without risk of unauthorised cluster participation. All other ports (REST API 9094, proxy 9095, pinning 9097, metrics 8888) must remain firewalled — they expose cluster control, pin operations, or internal state.

## Cross-host clustering

Local auto-discovery only finds peers whose `identity.json` files are on the **same host**. When cluster peers run on different hosts, declare the foreign peers via `ipfscluster_remote_peers`:

```yaml
# On host A (has ipfscluster0, ipfscluster1):
ipfscluster_instances:
  - name: ipfscluster0
    ...

ipfscluster_remote_peers:
  - id: "12D3KooW..."                                           # from host B's identity.json
    address: "/dns6/host-b.example.com/tcp/9096/p2p/12D3KooW..."

# On host B (has ipfscluster2):
ipfscluster_instances:
  - name: ipfscluster2
    ...

ipfscluster_remote_peers:
  - id: "12D3KooW..."                                           # from host A's identity.json
    address: "/dns6/host-a.example.com/tcp/9096/p2p/12D3KooW..."
  - id: "12D3KooW..."                                           # another peer on host A
    address: "/dns6/host-a.example.com/tcp/9097/p2p/12D3KooW..."
```

The role does two things with remote peers:

1. **trusted_peers** — remote peer IDs are merged with locally-discovered ones. If `ipfscluster_trusted_peers` is set explicitly (non-empty), it takes **full precedence** — you must include ALL desired peer IDs (local + remote) in it.
2. **cluster.peer_addresses** — remote peer multiaddresses are injected so peers can dial each other across hosts. Without these, peers on different hosts cannot find each other (mDNS doesn't cross podman bridges).

Addresses must use **host FQDNs or IPs** with the swarm port **published** on the remote host — not `*.dns.podman`. Multiple cluster peers behind one host each need a distinct published host port (e.g. 9096, 9097, 9098).

### Interaction with `ipfscluster_trusted_peers`

| `ipfscluster_trusted_peers` | Behavior |
|---|---|
| Empty (default) | Auto-discover local peer IDs + merge `ipfscluster_remote_peers` IDs |
| Non-empty | **Full override** — use only the listed IDs; ignore both local discovery and remote peers |

### Two-phase deploy (unavoidable)

Cluster PeerIDs are cryptographic identities generated at `ipfs-cluster-service init` time — they cannot be predicted. To add a peer on a new host:

1. **Init phase** — run the role on the new host only. It generates `identity.json`. Read the new PeerID from it (`id` field).
2. **Wire phase** — add the new PeerID + cross-host multiaddress to `ipfscluster_remote_peers` on existing hosts, and add existing hosts' peers to the new host's `ipfscluster_remote_peers`. Re-run the role on all hosts. `service.json` re-renders with the full trusted_peers list and peer_addresses; handlers restart containers.

### Publishing ports

| Port | Purpose | Publish publicly? | Protected by |
|------|---------|-------------------|--------------|
| 9096/tcp+udp | Cluster swarm (libp2p) | **Yes** — safe with cluster secret | PSK + trusted_peers |
| 9094 | REST API | **No** — cluster control | — |
| 9095 | IPFS Proxy | **No** — proxies to kubo | — |
| 9097 | Pinning Service API | **No** — pin operations | — |
| 8888 | Prometheus metrics | **No** — internal state | — |

On a **LAN host**, publishing 9096 is optional — peers can reach each other via host IPs. On a **public-IP host**, publish 9096 so remote peers can dial in. Keep all other ports firewalled or restricted to trusted IPs.

Multiple cluster peers on the same host each need a distinct published host port (e.g. 9096, 9097, 9098) since they share the host's IP.
