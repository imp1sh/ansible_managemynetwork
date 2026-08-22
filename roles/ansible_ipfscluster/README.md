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
| `ipfscluster_trusted_peers` | `[]` | Trusted peer IDs. If empty, auto-discovered from `identity.json` files. |
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
