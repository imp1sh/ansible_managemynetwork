ansible_talos
=========

A role to bootstrap and manage Talos Linux clusters. Generates machine configs,
deploys them to nodes, bootstraps etcd, and exports kubeconfig/talosconfig.

- Only static IP configuration is supported
- The role prepares OS upgrades (client + machine configs); the node rollout
  itself is manual and must be gated on etcd and workload health — see
  [Upgrading Talos](#upgrading-talos)

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
| `talos_talosctl_version` | `"{{ talos_version }}"` | talosctl binary version to install. The role reinstalls the binary whenever the effective version differs |
| `talos_talosctl_path` | `"/usr/local/bin/talosctl"` | Path of the managed talosctl binary |
| `talos_talosctl_arch` | `"amd64"` | Architecture suffix of the talosctl release asset (`amd64`, `arm64`) |
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
| `hosts_controlplane` | yes | List of CP nodes with `name` and `ip4`. Optional per-node `schematic_id` and `vip_interface` overrides. |
| `hosts_worker` | no | List of worker nodes with `name` and `ip4` |

### Schematic ID

The schematic ID identifies a pre-built installer image recipe at
`factory.talos.dev`. It determines which system extensions (kernel modules,
firmware, tools) are bundled into the Talos installer image.

Configurable at four levels (last one wins):
1. Role default: `talos_schematic_id` in `defaults/main.yml`
2. Group vars: `talos_schematic_id` in consuming playbook's group_vars
3. Per cluster: `talos_clusters.<name>.schematic_id`
4. Per control-plane node: `talos_clusters.<name>.hosts_controlplane[].schematic_id`

The per-node override is applied through the host-specific
`UnattendedInstallConfig` patch and only affects that node's install/upgrade
image. The cluster-wide installer image is still generated from the
cluster/global schematic, so nodes without an override keep using it.

The default schematic (`376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba`)
has `customization: {}` — plain vanilla Talos with no extensions. The same
schematic works across all Talos versions; only the `:tag` (version) changes.

To get a new schematic (when you need extensions):
- Visit `https://factory.talos.dev/new`, configure extensions, submit
- Or POST a schematic to `https://factory.talos.dev/schematics`
- Note the generated ID and set it as `schematic_id`

Example with extensions for a single node only:

```yaml
talos_clusters:
  junicluster0:
    hosts_controlplane:
      - name: "talos0"
        ip4: ["10.10.112.172/24"]
      - name: "talos1"
        schematic_id: "<schematic-id-with-extensions>"
        ip4: ["10.10.112.173/24"]
```

### Install disk selection

By default the role uses the first non-loop disk reported by
`talosctl get disks`. That is unsafe on machines with more than one disk.
Set `install_disk_selector` to an explicit CEL expression instead:

```yaml
hosts_controlplane:
  - name: "talos1"
    ip4: ["10.10.112.173/24"]
    install_disk_selector: 'disk.serial == "<serial>"'
    install_disk_wipe: true
```

Use a stable property (`disk.serial`, `disk.wwid`, or a
`/dev/disk/by-id/...` entry in `disk.symlinks`) and verify it with:

```bash
talosctl --nodes <node> get disks --insecure -o yaml
```

`install_disk_wipe` overrides the generated `wipe` value for that node. Set it
to `true` for a clean install on a disk that already contains partitions.

### User volumes

Additional disks can be provisioned as Talos user volumes and are mounted at
`/var/mnt/<name>`. Define them per control-plane node:

```yaml
hosts_controlplane:
  - name: "talos1"
    ip4: ["10.10.112.173/24"]
    user_volumes:
      - name: "local-path"
        disk_selector: 'disk.serial == "<disk-serial>"'
        min_size: "1TiB"
        grow: true
        filesystem: xfs
```

`disk_selector` is a CEL expression evaluated against the Talos `Disk`
resources. Use a stable property (`disk.serial`, `disk.wwid`, or
`disk.symlinks`), especially on machines with multiple disks.

### Kernel modules

Load additional kernel modules per node with `kernel_modules`:

```yaml
hosts_controlplane:
  - name: "talos2"
    ip4: ["10.10.112.174/24"]
    kernel_modules:
      - nvidia
      - nvidia_uvm
      - nvidia_drm
      - nvidia_modeset
```

Each entry renders a `KernelModuleConfig` document in the host patch. This is
required for the NVIDIA GPU extensions.

### Per-node VIP interface

The VIP is announced by every control-plane node, so each node's
`Layer2VIPConfig` must point at an interface that actually exists on that node:

```yaml
talos_clusters:
  junicluster0:
    vip: "10.10.112.20"
    vip_interface: "ens3"          # cluster-wide fallback
    hosts_controlplane:
      - name: "talos0"
        vip_interface: "ens3"
        ip4: ["10.10.112.172/24"]
      - name: "talos1"
        vip_interface: "enp191s0"
        ip4: ["10.10.112.173/24"]
      - name: "talos2"
        vip_interface: "enp9s0"
        ip4: ["10.10.112.174/24"]
```

Without a per-node override, the cluster-wide `vip_interface` is used, which is
only safe when every node has an interface with that name.

## Upgrading Talos

### What the role does vs. what stays manual

The role handles:

- Installing/updating `talosctl` declaratively: if the effective binary does
  not report `talos_talosctl_version`, it is re-downloaded. Re-running the role
  is therefore enough to align the client with the pinned version.
- Regenerating machine configs with the target install-image URL.
- Applying machine config changes via `talosctl apply-config`.

The role does **not**:

- Run `talosctl upgrade` (that is what replaces the OS image on disk).
- Reboot nodes or decide the upgrade order.

Those steps are manual because only the operator knows the workload topology
(etcd quorum, database primaries, maintenance windows).

### Constraints

- **Downgrades are not supported.** Talos only rolls forward.
- **Upgrade control-plane nodes one at a time.** With 3 CP nodes etcd tolerates
  one unavailable member, never two.
- **Do not batch workers that host stateful workloads.** A worker running a
  database replica, a quorum member, or similar is upgraded like a control
  plane node: one at a time, with health gates. Stateless workers may be
  upgraded together.
- **Snapshot and back up before starting.** VM snapshots are the only fast
  rollback for the OS; database backups are the only rollback for data.
- **Read the upstream release notes** for the target version:
  `https://www.talos.dev/latest/talos-guides/upgrading-talos/`

### Version sources

All version fields must be set to the same target version:

```yaml
talos_version: "<target-version>"           # install-image tag / role default
talos_talosctl_version: "<target-version>"  # managed talosctl binary
talos_clusters:
  <cluster>:
    talos_version: "<target-version>"       # per-cluster override
    talosctl_version: "<target-version>"    # must match the global value
```

The role asserts that every `talos_clusters.<name>.talosctl_version` equals
`talos_talosctl_version`, because only one `talosctl` binary is managed per
controller.

If the target requires different system extensions, set the schematic too:

```yaml
talos_clusters:
  <cluster>:
    schematic_id: "<new-schematic-id>"
```

If only selected control-plane nodes need the extensions, set the schematic on
those hosts instead:

```yaml
talos_clusters:
  <cluster>:
    hosts_controlplane:
      - name: "<node>"
        schematic_id: "<new-schematic-id>"
        ip4: ["<ip>/<prefix>"]
```

The upgrade image for such a node must be built from that node's schematic;
upgrading it with the cluster-wide vanilla image removes the extensions again.

### Step 1 - Pre-flight checks

```bash
# Talos versions currently running
talosctl --nodes <node-ip> version

# Cluster health (health keys off --nodes)
talosctl --nodes <control-plane-ip> health

# etcd: all members present, no learners
talosctl --nodes <control-plane-ip> etcd members

# Kubernetes and workloads
kubectl get nodes -o wide
kubectl get pods -A --field-selector=status.phase!=Running
```

If a CloudNativePG cluster runs on the cluster, verify it is fully healthy
**before** touching any node:

```bash
kubectl get clusters.postgresql.cnpg.io -A
# READY must equal INSTANCES and STATUS must be "Cluster in healthy state"

# Which node hosts the current primary? Upgrade that node last.
DB_NS=<cnpg-namespace>
DB_CLUSTER=<cnpg-cluster-name>
PRIMARY=$(kubectl -n "$DB_NS" get cluster "$DB_CLUSTER" -o jsonpath='{.status.currentPrimary}')
kubectl -n "$DB_NS" get pod "$PRIMARY" -o wide
```

Take an on-demand backup first if your policy requires it (requires the
kubectl-cnpg plugin), for example:

```bash
kubectl cnpg backup "$DB_CLUSTER" -n "$DB_NS"
```

### Step 2 - Bump the version and run the role

Edit the version fields above, commit, then run the consuming playbook:

```bash
ansible-playbook <playbook-using-ansible_talos>
```

Verify the result before upgrading any node:

```bash
# Controller now has the target client
talosctl version --client

# Machine configs reference the target installer image
talosctl --nodes <node-ip> get machineconfig -o yaml | grep -m1 'image:'

# Nodes still run the old OS image at this point
talosctl --nodes <node-ip> version
```

### Step 3 - Build the install image reference

```bash
TARGET_VERSION="<target-version>"
SCHEMATIC_ID="<schematic-id>"
INSTALL_IMAGE="factory.talos.dev/metal-installer/${SCHEMATIC_ID}:${TARGET_VERSION}"

# Without a factory schematic (vanilla image):
# INSTALL_IMAGE="ghcr.io/siderolabs/installer:${TARGET_VERSION}"
```

### Step 4 - Rolling upgrade

Upgrade one node at a time and pass the gates in Step 5 after every node before
touching the next one.

Order rules:

1. If a CNPG cluster exists, upgrade the node hosting the **current primary**
   **last** - that node causes a failover when it reboots.
2. Upgrade all other control-plane nodes sequentially.
3. Stateless workers may be batched; workers hosting a database instance, etcd,
   or any other quorum member are upgraded one at a time.

```bash
talosctl --nodes <node-ip> upgrade --image "$INSTALL_IMAGE"
```

`talosctl upgrade` drains the node by default (`--drain`, 5 minute timeout),
reboots it, runs the post-check and uncordons it. A
`server version ... is older than client version ...` warning during the
upgrade is expected: it is the pre-upgrade comparison, and the post-check runs
after the reboot.

### Step 5 - Gates after every node

Do not continue until **all** of the following pass:

```bash
# New Talos version on the upgraded node
talosctl --nodes <node-ip> version

# Node Ready, new OS image/kernel/containerd
kubectl get nodes -o wide

# Talos/etcd health for control-plane nodes
talosctl --nodes <control-plane-ip> health
talosctl --nodes <control-plane-ip> etcd members   # all members, no learners

# No non-running pods
kubectl get pods -A --field-selector=status.phase!=Running
```

With CNPG, also wait until the database is fully healthy again:

```bash
kubectl -n "$DB_NS" get cluster "$DB_CLUSTER"
# READY == INSTANCES and STATUS == "Cluster in healthy state"

# Or block until the Ready condition is true. Use a generous timeout: a former
# primary may have to archive a large WAL backlog first (see Step 6).
kubectl -n "$DB_NS" wait --for=condition=Ready "cluster/$DB_CLUSTER" --timeout=45m
```

Never start the next node while a database instance is still recovering.

### Step 6 - CNPG behavior during node reboots

This is the part that most often makes an otherwise healthy upgrade look stuck.

| Node hosted | Expected behavior |
|-------------|-------------------|
| a replica | The pod restarts and rejoins via streaming replication; usually ready within minutes. |
| the primary | The operator promotes a replica (brief write interruption); the old primary restarts and rejoins as a replica. |

The slow case is a **former primary with unarchived WALs**. Before PostgreSQL
starts, the instance manager archives the leftover WAL segments from its
`pg_wal` directory. If WAL archiving had been lagging, that backlog can be many
gigabytes and take tens of minutes. The pod stays `1/2 Ready` and logs:

```
"This is an old primary instance, waiting for the switchover to finish"
"Switchover completed"
"Waiting for the new primary to be available"
"Detected ready WAL files in a former primary, triggering WAL archiving"
```

Check that it is progressing - and do **not** delete the pod while it is
archiving, because that discards the progress. With the Barman Cloud plugin
the archiving happens in the `plugin-barman-cloud` sidecar; with in-tree
Barman the same messages appear in the instance-manager (`postgres`) log:

```bash
kubectl -n "$DB_NS" logs <pod> -c plugin-barman-cloud -f | grep "Archived WAL file"
```

Only if there is genuinely no progress, follow the CNPG troubleshooting
runbook; deleting the pod forces a rebuild from a base backup.

After the upgrade, investigate why archiving lagged: a declared `walStorage`
size is not enforced by every storage provisioner, so a large backlog can
consume node disk. Check archive health and volume usage, and consider raising
`walStorage` or alerting on archive lag.

### Step 7 - Final verification

```bash
for ip in <node-ip-1> <node-ip-2> <node-ip-3>; do
  echo -n "$ip: "
  talosctl --nodes "$ip" version | awk '/^Server:/{s=1} s&&/Tag:/{print $2; exit}'
done

kubectl get nodes -o wide
kubectl get pods -A --field-selector=status.phase!=Running
talosctl --nodes <control-plane-ip> etcd members

# If CNPG is present
kubectl get clusters.postgresql.cnpg.io -A
kubectl -n "$DB_NS" get cluster "$DB_CLUSTER" \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
```

Re-running the role once more is a good idempotence check: it should skip the
talosctl download and apply no machine-config changes.

### Rollback

True rollback (downgrade) is not supported. Options if an upgrade goes wrong:

1. **Snapshot restore** - revert the VM snapshots taken before the upgrade.
   Preserves all cluster state.
2. **Reset and rebuild** - `talosctl reset` on the affected node(s), then
   redeploy with the old version via this role. This destroys local state on
   those nodes (etcd, local-path volumes).
3. **CNPG restore** - if the database is lost, restore it from the Barman
   ObjectStore backup taken before the upgrade (see the CNPG backup docs).

Always snapshot and verify backups before upgrading.

### Troubleshooting quick reference

| Symptom | Meaning / action |
|---------|------------------|
| `server version ... is older than client version ...` during upgrade | Expected pre-reboot check; the post-check after the reboot validates the new version. |
| `talosctl health` fails with "nodes are not set" | Use `--nodes`, not `--endpoints`, with `health`. |
| `etcd members` fails with "failed to determine endpoints" | Pass `--nodes <ip>`; do not rely on the context endpoints alone. |
| Node stays `NotReady` after reboot | `talosctl --nodes <ip> health`, `kubectl describe node <node>`, `talosctl --nodes <ip> dmesg`. |
| CNPG "Waiting for the instances to become active" | At least one instance is not ready. Check `kubectl -n <ns> logs <pod> -c postgres`; a former primary may be archiving WALs (Step 6). |
| CNPG former primary logs "Detected ready WAL files ..." | Archiving backlog; wait and watch the barman sidecar logs. Do not delete the pod. |
| CNPG pod `1/2` with "no such file or directory ... .s.PGSQL.5432" | PostgreSQL has not started yet; that log is a symptom, not the cause. Check the archive/instance-manager path. |
