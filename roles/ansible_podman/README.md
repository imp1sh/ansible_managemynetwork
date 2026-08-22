# imp1sh.ansible_managemynetwork.ansible_podman
This role sets up podman containers, networks and secrets. It utilizes the official [podman community collection](https://docs.ansible.com/ansible/latest/collections/containers/podman/podman_container_module.html).

## Supported OSes
- Debian
- Fedora (incl. SELinux and firewalld support)
- OpenWrt (imagebuilder support is yet to come)

## Supported Features
Supporting the following roles from the [containers.podman collection](https://galaxy.ansible.com/ui/repo/published/containers/podman/).
- podman_containers
- podman_secrets
- podman network
- Run only on specific containers by setting `podman_limited_containers` to a **list** of container instance names (e.g. `["borgmatic0"]`). By default the role iterates over all defined containers for the host. This also filters which plugins run — only plugins whose registered container names intersect the limited list are executed.
- Optional Quadlet backend (recommended on Podman >= 4.4 / 5.x). See [Quadlet](#quadlet) below.

# Role Workflow

- Handling all the common podman stuff like:

**0install.yml**: Installing Podman required OS packages

**1prepare.yml**:
  - Creating podman networks
  - Applying limit when choosing explicit container via *podman_limited_containers*
  - Making sure the necessary folders for the container exist
  - We see logging into dockerhub as mandatory as they limit to 10 images per hour per IP since April 1st of 2025. Set `podman_dockerio_username` and `podman_dockerio_password`

**main.yml**:
  - The dispatcher. Installs podman secrets, includes the plugin chooser, creates containers with the `containers.podman.podman_containers` module (or via Quadlet — see below), runs the second plugin pass, and finally includes `4post.yml`.

**2plugin_chooser.yml**:
  - Meta task that delegates to the specific plugin files, e.g. *plugin_psql_run1.yml*. Each plugin calls another role from MMN that has been adapted to manage the configuration of a podman container.
  - Enabling a plugin is done via a `podman_container_plugin_<name>` list naming the container instances it should run against — no `plugin` key on the container definition is needed. Here the psql plugin runs for the `psql0` container:
```yaml
podman_container_plugin_psql:
  - "psql0"
```
  - For detailed information on each plugin, see the README of the corresponding role, e.g. `ansible_psqlserver` for the `psql` plugin.

**plugin_psql_run2.yml**
  - Some plugins require the plugin's role to run a second time: psql, for example, expects an empty data dir at first initialization. After the container has been initialised, only then can the target configuration files be placed.

**4post.yml**

Post-container tasks:
- Opening published container ports in firewalld on non-OpenWrt hosts where firewalld is active.
- Deploying the OpenWrt hotplug iface script that reloads podman networking on interface events.
- Managing service state for the container. Possible state values for your container element definition:
  - started
  - present
  - stopped
  - absent

  split into two OS-specific variants:

  **3systemd.yml** (non-OpenWrt):
    - Generate systemd service unit files via `podman generate systemd` and set the correct state.

  **3procd.yml** (OpenWrt):
    - Deploy procd init scripts and enable them.

## Containers
It basically works like this. You define the variable `podman_containers`. Normally you don't set static IP addresses though.
```yaml
podman_containers:
  - name: hoarder0
    state: started
    network: podmannetGUA
    ip: 10.10.151.3
    ip6: 20a1:64c:fb4:1002::3
    image: ghcr.io/hoarder-app/hoarder:latest
    volume:
      - "/mnt/cntr/unsynced/hoarder/0/data/:/data"
    ports:
      - 3331:3000
    env:
      MEILI_ADDR: "http://meilisearch0:7700"
      BROWSER_WEB_URL: "http://chrome0:9222"
      DATA_DIR: /data
```
## Secrets
This will effectively put the secret into a plaintext file at `/run/secrets/<name>`.
```yaml
podman_secrets:
  - name: "psql0_replicationuser_password"
    state: "present"
    data: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          35323931333265623632626333646437223431313766313963666364373163326132313738323035
          [...]
          636638633633343336663639623766373231263313333663562663131303865326162
```

## Networks
Manage podman networks for you, see this example:
```yaml
podman_networks:
  - name: podmannetGUA
    driver: bridge
    ipv6: True
    net_config:
      - subnet: "10.10.151.0/24"
        gateway: "10.10.151.1"
      - subnet: "20ae:17c:fb6:1002::/64"
        gateway: "20ae:17c:fb6:1002::1"
```


## Storage
You can define where podman data will be stored by setting this variable.
```
podman_storageconfig_graphroot: "/mnt/container/storage"
```
This is especially important on OpenWrt as by default podman stores on /var which is a non persistent volume. Each reboot all your container data will be gone.

## Quadlet

By default this role manages container lifecycle with the (now deprecated)
`podman generate systemd` path, producing `container-<name>.service` units in
`/etc/systemd/system`. That approach bakes the container id into a
`Type=forking` unit's `PIDFile=`, so whenever a container is recreated (new id)
the unit keeps pointing at the old id and systemd enters a start/timeout/restart
loop. Quadlet is the upstream replacement and avoids this entirely: the
`.container` unit is a declaration of desired state and systemd regenerates the
transient service correctly on every reload.

Enable Quadlet per host:

```yaml
podman_use_quadlet: true
```

When set, the role will (instead of `podman_containers` + `podman generate
systemd`):
- render `<name>.container` units into `/etc/containers/systemd/` (override
  path with `podman_quadlet_dir`),
- on first adoption stop/disable/delete any legacy `container-<name>.service`
  and remove the stray imperative container (bind-mount data is preserved),
- `systemctl daemon-reload` and enable+start `<name>.service`,
- on `.container` file changes `systemctl restart <name>.service` so the new
  config is applied (Quadlet recreates the container).

Plugin handlers (psql/borgmatic/pdnsauth) automatically target the right unit
name (`<name>` under Quadlet, `container-<name>` otherwise) based on
`podman_use_quadlet`, so no inventory changes are required besides flipping the
flag.

Supported `podman_containers` keys mapped to the `.container` file: `name`,
`image`, `state`, `network`, `ip`, `ip6`, `volume`/`volumes`, `ports`/`publish`,
`env`, `cap_add`, `cap_drop`, `user`, `group`, `timezone`, `readonly_rootfs`,
`dns`, `label`/`labels`, `secret`/`secrets`, `hostname`, `command`, `pull`,
`tmpfs`, `selinux_type`, `selinux_disable`.
Optional tuning keys: `stop_timeout` (default 10), `start_timeout` (default
180), `kill_signal` (e.g. `SIGINT` for PostgreSQL smart shutdown).

## Fedora / SELinux

On Fedora SELinux is enforcing by default. A container process (type
`container_t`) cannot access the Podman API socket (`podman.sock`) — SELinux
denies it because the socket belongs to the podman runtime. This affects
containers that need to talk to the Podman API, e.g. traefik with the Podman
provider.

### Automatic detection (Quadlet path)

When `podman_use_quadlet: true` the role detects the situation automatically:
if the target host has SELinux in enforcing mode **and** a container mounts a
volume whose path contains `podman.sock` or `docker.sock`, the role emits
`SecurityLabelType=container_runtime_t` for that container without any user
input. This gives the container process the same SELinux type that podman
itself uses, granting socket access without disabling SELinux.

Explicit settings take precedence over auto-detection:
- `selinux_disable: true` disables SELinux confinement entirely (last resort).
- `selinux_type: "<type>"` sets an arbitrary type, overriding the auto-detected
  `container_runtime_t`.

### Manual override

If you need a different type or use the non-Quadlet path, set it explicitly:

```yaml
podman_containers:
  - name: traefik0
    state: started
    image: docker.io/traefik:v3.0
    network: podmannetGUA
    volume:
      - "/run/podman/podman.sock:/run/podman/podman.sock"
    selinux_type: "container_runtime_t"
```

For the non-Quadlet path (`podman_use_quadlet: false`) pass `security_opt`
directly — the `podman_containers` module forwards it unchanged:

```yaml
podman_containers:
  - name: traefik0
    ...
    security_opt:
      - "label=type:container_runtime_t"
```

To disable SELinux confinement entirely for a container (last resort), set
`selinux_disable: true` (Quadlet) or `security_opt: ["label=disable"]`
(non-Quadlet).

## OpenWrt specifics
Podman will be deployed on OpenWrt using aardvark-dns. This will clash with dnsmasq as it will usually bind to all interfaces, also the podman interface. This is why it is a requirement to only bind dnsmasq to specific interfaces and blacklist it for others like this.

### OpenWrt DNS

```yaml
openwrt_dhcp_dnsmasq_notinterface:
  - "podman0"
  - "wan"
  - "wan6"
openwrt_dhcp_dnsmasq_interface:
  - "lan"
```

### OpenWrt Networks

Networks are being handled via podman network role with the exception of OpenWrt. In OpenWrt networks are deployed via jinja2 template as a workaround because otherwise it would clash. In OpenWrt you will have to setup a bridge interface manually via `ansible_openwrtnetwork` role first. Then configure the podman network a bit differently on OpenWrt. You need to specify an ID yourself and the created timestamp as well. `interface_name` is the name of the bridge interface. Example:

```yaml
podman_networks:
  - name: "podmannet"
    created: "2025-02-20T08:56:34.652030952Z"
    driver: "bridge"
    id: "5ef894781befe4d42498314b6e66282ca730aa2e1e82f9b9597bf1d1724ea011"
    interface_name: "podman0"
    ipv6: true
    net_config:
      - subnet: "{{ openwrt_network_interfaceshost['podman0'].ipaddr.0 | ansible.utils.ipaddr('network/prefix') }}"
        gateway: "{{ openwrt_network_interfaceshost['podman0'].ipaddr.0 | ansible.utils.ipaddr('address') }}"
      - subnet: "{{ openwrt_network_interfaceshost['podman0'].ip6addr.0 | ansible.utils.ipaddr('network/prefix') }}"
        gateway: "{{ openwrt_network_interfaceshost['podman0'].ip6addr.0 | ansible.utils.ipaddr('address') }}"
```

### OpenWrt Firewall

Define an OpenWrt firewall zone for the container network
```yaml
openwrt_firewall_zoneshost:
  CONTAINER:
    forward: "REJECT"
    input: "DROP"
    output: "ACCEPT"
    log: 1
    interfaces:
      - "podman0"
```
In most cases you will want to allow Internet access for your container zone.
```yaml
openwrt_firewall_forwardingshost:
  [...]
  - src: "CONTAINERS"
    dest: "WAN"
```

### OpenWrt Storage

As you want persistent storage, you should create an fstab mount. Determine your disks uuid by installing `blkid` on OpenWrt and then query your devices.

```bash
apk add blkid
blkid
```

Then create the fstab entry with your disks uuid and your chosen mountpoint.

```yaml
openwrt_fstab_mount:
  - "target": '/mnt/container'
    "uuid": 'eca245a6-ee59-4ec2-9704-2076ffab7e90'
    'enabled': '1'
```

### OpenWrt Containers

You will need to create static IP addresses in case you plan to forward traffic to them. If you do not need that and utilize caddy or traefik you won't need this as both are container aware and will automatically updated their target IP.

```yaml
podman_containers:
  - name: homepage1
    state: started
    network: podmannet
    ip: "10.166.0.10"
    ip6: "fd10:166:4d21:d83c::a"
    image: ghcr.io/gethomepage/homepage:latest
    volume:
      - "/mnt/cntr/unsynced/homepage/1/config/:/app/config"
      - "/mnt/cntr/unsynced/homepage/1/images/:/app/public/images"
    ports:
      - "8080:80"
      - "4443:443"
```

## Plugins
This is supposed to work as a plugin system. The idea is to not only deploy a working container but also deploy the configuration for that very target application. The idea is to achieve an Infrastructure as Code (IaC) mode for this role.
Supported plugin:

| Plugin name | Related Ansible role | Description |
| - | - | - |
| psql | [imp1sh.ansible_managemynetwork.ansible_psqlserver](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_psqlserver) | |
| borgmatic | [imp1sh.ansible_managemynetwork.ansible_borgmatic](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_borgmatic) | |
| pdnsauth | [imp1sh.ansible_managemynetwork.ansible_pdnsauth](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_pdnsauth) | |
| prometheus | [imp1sh.ansible_managemynetwork.ansible_prometheus](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_prometheus) | Renders `prometheus.yml` + rule files for the prometheus container |
| traefik | [imp1sh.ansible_managemynetwork.ansible_traefik](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_traefik) | Renders `traefik.yml` static config, dynamic file-provider configs and `acme.json` |
| grafana | [imp1sh.ansible_managemynetwork.ansible_grafana](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_grafana) | Renders `grafana.ini` and datasource/dashboard provisioning files |
| opensearch | [imp1sh.ansible_managemynetwork.ansible_opensearch](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_opensearch) | Renders `opensearch.yml` for the opensearch container |
| ipfscluster | [imp1sh.ansible_managemynetwork.ansible_ipfscluster](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_ipfscluster) | Bootstraps IPFS Cluster peers — generates identities, auto-discovers peer IDs, renders `service.json` |
| kubo | [imp1sh.ansible_managemynetwork.ansible_kubo](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_kubo) | Bootstraps Kubo (IPFS) nodes — initialises repo, auto-discovers peer IDs for Peering, renders `config` |
| dnsdist | planned | |
| cacert | planned | |

### borgmatic
Here's a typial `podman_containers` excerpt for how a borgmatic container definition could look like:

```yaml
podman_containers:
  - name: borgmatic_cntr-ofden1
    state: started
    network: podmannetGUA
    hostname: "{{ inventory_hostname }}"
    image: ghcr.io/borgmatic-collective/borgmatic
    volume:
      - "/mnt/cntr/unsynced/borgmatic/0/repository/:/mnt/borg-repository/"
      - "/mnt/cntr/unsynced/borgmatic/0/borgmatic.d/:/etc/borgmatic.d/"
      - "/mnt/cntr/unsynced/borgmatic/0/config/:/root/.config/borg/"
      - "/mnt/cntr/unsynced/borgmatic/0/ssh/:/root/.ssh/"
      - "/mnt/cntr/unsynced/borgmatic/0/root/:/root/.local/state/borgmatic/"
      - "/mnt/cntr/unsynced/:/mnt/source/:ro"
    env:
      TZ: "Europe/Berlin"
  - name: borgmatic_cntr-ofden1_restore
    state: stopped
    network: podmannetGUA
    hostname: "{{ inventory_hostname }}"
    image: ghcr.io/borgmatic-collective/borgmatic
    volume:
      - "/mnt/cntr/unsynced/borgmatic/0/repository/:/mnt/borg-repository/"
      - "/mnt/cntr/unsynced/borgmatic/0/borgmatic.d/:/etc/borgmatic.d/"
      - "/mnt/cntr/unsynced/borgmatic/0/config/:/root/.config/borg/"
      - "/mnt/cntr/unsynced/borgmatic/0/ssh/:/root/.ssh/"
      - "/mnt/cntr/unsynced/borgmatic/0/root/:/root/.local/state/borgmatic/"
      - "/mnt/cntr/unsynced/:/mnt/source/"
    env:
      TZ: "Europe/Berlin"
```
The restore container is there in standby only in case you would want to restore something.
Look into the `ansible_borgmatic` role's docs in order to find out about how to set borgmatic variables specific to running in a container.

### psql
Here's an example of a postgresql container when when using the psql plugin.
```
podman_containers:
  - name: "psql0"
    state: started
    network: podmannetGUA
    image: docker.io/postgres:17.4-bookworm
    command: |
      postgres
      -c max_connections=500
    volume:
      - "/mnt/cntr/unsynced/psql/0/data/:/var/lib/postgresql/data/"
      - "/mnt/cntr/unsynced/psql/0/init/1_pdns_init.sh:/docker-entrypoint-initdb.d/1_pdns_init.sh"
      - "/mnt/cntr/unsynced/psql/0/init/2_pdns_47.sql:/docker-entrypoint-initdb.d/2_pdns_47.sql"
    env:
      POSTGRES_PASSWORD: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          35636565373238333965313735306138326633356365653137323037383962323638656434343531
          [...]
          6161
```

### pdnsauth

Authoritative PowerDNS Nameserver podman plugin.
Here's an example Ansible variable set.

``` yaml
pdns_webserver_address: "::"
pdns_webserver_allow_from: "2003:a:124c:9100::/56,2001:12c:cfb8::/48"
pdns_path_config: "/mnt/cntr/unsynced/pdnsauth/0"
pdns_gpgsql_host: "psql0"
pdns_gpgsql_user: "pdns"
pdns_gpgsql_dbname: "pdns"
# pdns_gpgsql_extra_connection_parameters: "sslmode=verify-full sslrootcert=/etc/powerdns/main_jochenit_ca_certificate.pem"
pdns_gpgsql_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          37613133386138666538386534396431336261643336346133393230343437626639396665616433
          [...]
          33346232613939623939663264346635383339326135616235326164633735373565
```

Also specify the container name for using the plugin:

```yaml
podman_container_plugin_pdnsauth:
  - "pdnsofden0"
```

Here's a container example definition as well
```yaml
podman_containers:
  - name: pdnsofden0
    state: present
    network: podmannetGUA
    ip: 10.10.151.73
    ip6: 2001:12c:fc8:1004::58
    cap_add:
      - "CAP_NET_BIND_SERVICE"
    image: docker.io/powerdns/pdns-auth-master
    volume:
      - /mnt/cntr/unsynced/pdnsauth/0/pdns.conf:/etc/powerdns/pdns.conf
      - /mnt/cntr/unsynced/pdnsauth/0/main_jochenit_ca_certificate.pem:/etc/powerdns/main_jochenit_ca_certificate.pem:ro
    ports:
      - 8083:8081
```

### prometheus

Prometheus server plugin. The `ansible_podman` role spins up the container; the
[`ansible_prometheus`](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_prometheus)
role renders `prometheus.yml` and rule files into the host bind-mount
directories *before* the container starts. Enable the plugin for the
`prometheus0` container:

```yaml
podman_container_plugin_prometheus:
  - "prometheus0"
prometheus_containername: "prometheus0"
```

Then define the container and the prometheus vars:

```yaml
podman_containers:
  - name: prometheus0
    state: started
    network: podmannetGUA
    image: docker.io/prom/prometheus:latest
    volume:
      - "/mnt/cntr/unsynced/prometheus/0/etc/:/etc/prometheus/"
      - "/mnt/cntr/unsynced/prometheus/0/etc/rules/:/etc/prometheus/rules/"
      - "/mnt/cntr/unsynced/prometheus/0/data/:/prometheus/"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--storage.tsdb.retention.time=30d"
      - "--web.enable-lifecycle"
    ports:
      - "9090:9090"

prometheus_scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets:
          - "localhost:9090"
  - job_name: "node"
    static_configs:
      - targets:
          - "host1:9100"
          - "host2:9100"

prometheus_rules:
  node_alerts:
    - name: node.rules
      rules:
        - alert: NodeDown
          expr: 'up{job="node"} == 0'
          for: "5m"
          labels:
            severity: page
          annotations:
            summary: "Node {{ $labels.instance }} is down"
```

See the `ansible_prometheus` README for the full variable reference.

### traefik

Traefik reverse-proxy plugin. The `ansible_podman` role spins up the container;
the [`ansible_traefik`](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_traefik)
role renders the static config (`traefik.yml`), dynamic file-provider configs,
and initialises `acme.json` (mode `0600`, never overwritten) *before* the
container starts. Enable the plugin for the `traefik0` container:

```yaml
podman_container_plugin_traefik:
  - "traefik0"
traefik_containername: "traefik0"
```

Then define the container and the traefik vars:

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

traefik_entrypoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

traefik_providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    directory: "/etc/traefik/dynamic"
    watch: true

traefik_certificates_resolvers:
  letsencrypt:
    acme:
      email: "admin@example.com"
      storage: "/etc/traefik/acme.json"
      httpChallenge:
        entryPoint: web

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

On Fedora / SELinux-enforcing hosts the podman role auto-detects the podman
socket mount and emits `SecurityLabelType=container_runtime_t` under Quadlet —
see [Fedora / SELinux](#fedora--selinux) above. See the `ansible_traefik` README
for the full variable reference.

### grafana

Grafana visualization plugin. The `ansible_podman` role spins up the container;
the [`ansible_grafana`](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_grafana)
role renders `grafana.ini` and the datasource/dashboard-provider provisioning
files into the host bind-mount directories *before* the container starts.
Enable the plugin for the `grafana0` container:

```yaml
podman_container_plugin_grafana:
  - "grafana0"
grafana_containername: "grafana0"
```

Then define the container and the grafana vars:

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

grafana_ini:
  server:
    domain: "grafana.example.com"
    root_url: "%(protocol)s://%(domain)s/"
  security:
    admin_user: "admin"
    admin_password: "changeme"
  auth.anonymous:
    enabled: true
    org_role: "Viewer"

grafana_datasources:
  prometheus:
    - name: Prometheus
      type: prometheus
      access: proxy
      url: http://prometheus0:9090
      isDefault: true
```

See the `ansible_grafana` README for the full variable reference.

### ipfscluster

IPFS Cluster peer plugin. The `ansible_podman` role spins up the container;
the [`ansible_ipfscluster`](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_ipfscluster)
role generates cryptographic identities, auto-discovers peer IDs for the
trusted-peers list, and renders `service.json` *before* the container starts.
Enable the plugin for the cluster peer containers:

```yaml
podman_container_plugin_ipfscluster:
  - "ipfscluster0"
  - "ipfscluster1"
  - "ipfscluster2"
```

Then define the containers and the ipfscluster vars:

```yaml
podman_containers:
  - name: ipfscluster0
    state: started
    network: podmannet
    image: docker.io/ipfs/ipfs-cluster:v1.1.6
    env:
      CLUSTER_PEERNAME: cluster0
      CLUSTER_SECRET: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...
    volume:
      - "/filer0/ipfs/cluster0/:/data/ipfs-cluster"
  - name: ipfscluster1
    state: started
    network: podmannet
    image: docker.io/ipfs/ipfs-cluster:v1.1.6
    env:
      CLUSTER_PEERNAME: cluster1
      CLUSTER_SECRET: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...
      CLUSTER_BOOTSTRAP: /dns6/ipfscluster0.dns.podman/tcp/9096/p2p/12D3KooW...
    volume:
      - "/filer0/ipfs/cluster1/:/data/ipfs-cluster"

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
```

The role runs as a **pre-creation plugin** — `service.json` and
`identity.json` are in place before the container starts for the first time.
On subsequent runs, if `service.json` content changes, the role restarts the
affected container(s). See the `ansible_ipfscluster` README for the full
variable reference.

### kubo

Kubo (IPFS) node plugin. The `ansible_podman` role spins up the container;
the [`ansible_kubo`](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_kubo)
role initialises the IPFS repo, auto-discovers peer IDs for Peering, and
renders the full `config` *before* the container starts. Pairs naturally with
the `ipfscluster` plugin — Kubo provides the IPFS daemon, IPFS Cluster
coordinates pinning across multiple Kubo nodes. Enable the plugin:

```yaml
podman_container_plugin_kubo:
  - "ipfs0"
  - "ipfs1"
  - "ipfs2"
```

Then define the containers and the kubo vars:

```yaml
podman_containers:
  - name: ipfs0
    state: started
    network: podmannet
    image: docker.io/ipfs/kubo:v0.43.0
    volume:
      - "/filer0/ipfs/0/data/:/data/ipfs/"
      - "/filer0/ipfs/0/ipfs/:/ipfs"
      - "/filer0/ipfs/0/ipns/:/ipns"
    env:
      IPFS_PROFILE: "server"
      IPFS_TELEMETRY: "off"

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
```

The role runs as a **pre-creation plugin** — the IPFS repo and `config` are in
place before the container starts. Each node automatically peers with all
other nodes defined in `kubo_instances` (self excluded). Combined with
`kubo_peering_strict: true` and `kubo_routing_type: none`, this creates a
private mesh. See the `ansible_kubo` README for the full variable reference.


