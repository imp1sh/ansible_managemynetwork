ansible_talos
=========

A role to bootstrap and manage Talos Linux clusters. Generates machine configs,
deploys them to nodes, bootstraps etcd, and exports kubeconfig/talosconfig.

- Only static IP configuration is supported
- Upgrades are partially automated — see below

## Quick start

At the end of a successful run, retrieve your kubeconfig:
```bash
talosctl kubeconfig --nodes <masternode> --endpoints <masternode> --talosconfig ./talosconfig
```

## Variables

### Role defaults (`defaults/main.yml`)

| Variable | Default | Description |
|----------|---------|-------------|
| `talos_version` | `"v1.9.2"` | Talos OS version, used as install-image tag |
| `talos_talosctl_version` | `"{{ talos_version }}"` | talosctl binary version to install |
| `talos_secrets_file` | `"secrets.yaml"` | Secrets file name (preserved across runs) |
| `talos_filename_controlplane_patched` | `"controlplane_patched.yaml"` | Patched controlplane config filename |
| `cilium_chart_version` | `"1.20.2"` | Helm chart version for Cilium inline manifest |
| `talos_schematic_id` | `"376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"` | Factory schematic ID (vanilla, no extensions) |
| `cilium_gateway_api` | `false` | Enable Cilium Gateway API controller and install CRDs |
| `cilium_gateway_api_crd_version` | `"v1.2.1"` | Gateway API CRD version to install |

### Per-cluster variables (`talos_clusters.<name>`)

Each key under `talos_clusters` defines one cluster:

| Variable | Required | Description |
|----------|----------|-------------|
| `api_fqdn` | yes | API server endpoint (VIP or FQDN) |
| `vip` | yes | Virtual IP for control plane HA |
| `vip_interface` | yes | Interface for VIP (e.g. `ens3`) |
| `allowSchedulingOnControlPlanes` | no | Allow workload scheduling on CP nodes |
| `custom_cni` | no | Set to `cilium` for Cilium inline manifest |
| `disable_kube_proxy` | no | Disable kube-proxy (required with Cilium replacement) |
| `pod_subnets` | yes | List of pod CIDR ranges (IPv4 + IPv6) |
| `service_subnets` | yes | List of service CIDR ranges (IPv4 + IPv6) |
| `talos_version` | no | Per-cluster Talos version override |
| `talosctl_version` | no | Per-cluster talosctl version override |
| `schematic_id` | no | Per-cluster schematic ID override |
| `cilium_gateway_api` | no | Enable Cilium Gateway API (also installs CRDs as inline manifest) |
| `hosts_controlplane` | yes | List of CP nodes with `name` and `ip4` |
| `hosts_worker` | no | List of worker nodes with `name` and `ip4` |

### Schematic ID

The schematic ID identifies a pre-built installer image recipe at
`factory.talos.dev`. It determines which system extensions (kernel modules,
firmware, tools) are bundled into the Talos installer image.

Configurable at three levels (last one wins):
1. Role default: `talos_schematic_id` in `defaults/main.yml`
2. Group vars: `talos_schematic_id` in consuming playbook's group_vars
3. Per cluster: `talos_clusters.<name>.schematic_id`

The default schematic (`376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba`)
has `customization: {}` — plain vanilla Talos with no extensions. The same
schematic works across all Talos versions; only the `:tag` (version) changes.

To get a new schematic (when you need extensions):
- Visit `https://factory.talos.dev/new`, configure extensions, submit
- Or use `talosctl images schematic --extension <name> ...`
- Note the generated ID and set it as `schematic_id`

## Upgrading Talos

### What the role does vs. what is manual

The role handles:
- Installing/updating `talosctl` to the configured version
- Generating machine configs with the target install-image URL
- Applying machine config changes via `talosctl apply-config`

The role does **not** handle:
- Running `talosctl upgrade` to replace the Talos OS image on disk

OS upgrades must be performed manually after re-running the role.

### Constraints

- **Downgrades are not supported.** Talos only rolls forward.
- **Upgrade control plane nodes one at a time.** Etcd quorum must stay intact.
  With 3 CP nodes you can lose 1, never 2.
- **Snapshots before upgrading** are strongly recommended as the only rollback
  mechanism.

### Upgrade procedure

#### Step 1 — Update version in group_vars

Bump all version fields to the target version (e.g. `v1.15.0`):

```yaml
talos_version: "v1.15.0"
talos_talosctl_version: "v1.15.0"
talos_clusters:
  junicluster0:
    talos_version: "v1.15.0"
    talosctl_version: "v1.15.0"
```

If switching to a schematic with different extensions, also set:
```yaml
talos_clusters:
  junicluster0:
    schematic_id: "<new-schematic-id>"
```

Commit the change.

#### Step 2 — Re-run the role

```bash
ansible-playbook <playbook-using-ansible_talos>
```

This installs the new `talosctl`, regenerates machine configs with the new
install-image URL, and applies any config changes. Nodes are still running the
old Talos OS image at this point.

#### Step 3 — Upgrade nodes manually

Set the install image:
```bash
INSTALL_IMAGE="factory.talos.dev/metal-installer/${SCHEMATIC_ID}:${TARGET_VERSION}"
```

##### Control plane nodes (sequential)

Upgrade one node at a time. Wait for each to complete and return to healthy
before proceeding to the next:

```bash
talosctl --nodes <cp-node-1-ip> upgrade --image ${INSTALL_IMAGE}
talosctl --nodes <cp-node-1-ip> health

talosctl --nodes <cp-node-2-ip> upgrade --image ${INSTALL_IMAGE}
talosctl --nodes <cp-node-2-ip> health

talosctl --nodes <cp-node-3-ip> upgrade --image ${INSTALL_IMAGE}
talosctl --nodes <cp-node-3-ip> health
```

##### Worker nodes (parallel)

Workers can be upgraded simultaneously since they don't hold etcd:

```bash
talosctl --nodes <worker-ip-1> --nodes <worker-ip-2> upgrade --image ${INSTALL_IMAGE}
```

#### Step 4 — Verify

```bash
# All nodes reporting new version
talosctl --nodes <cp-1> --nodes <cp-2> --nodes <cp-3> version

# Kubernetes components healthy
talosctl --nodes <cp-1> health --server=false

# Pods running normally
kubectl get nodes -o wide
kubectl get pods -A
```

### Rollback

True rollback (downgrade) is not supported. Options if an upgrade goes wrong:

1. **Snapshot restore** — revert VM snapshots taken before the upgrade.
   Preserves all cluster state.
2. **Reset and rebuild** — `talosctl reset` on all nodes, then redeploy from
   scratch with the old version via this role. Destroys all cluster state
   (etcd, local volumes).

Always snapshot before upgrading.
