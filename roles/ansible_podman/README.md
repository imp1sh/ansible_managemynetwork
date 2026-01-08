# imp1sh.ansible_managemynetwork.ansible_podman
This role sets up podman containers, networks and secrets. It utilizes the official [podman community collection](https://docs.ansible.com/ansible/latest/collections/containers/podman/podman_container_module.html).

## Supported OSes
- Debian
- OpenWrt (imagebuilder support is yet to come)

## Supported Features
Supporting the following roles from the [containers.podman collection](https://galaxy.ansible.com/ui/repo/published/containers/podman/).
- podman_containers
- podman_secrets
- podman network
- Run only on specific containers by setting var `podman_limited_containers` to the container instance name. By default it will iterate over all defined containers for the host.

# Role Workflow

- Handling all the common podman stuff like:

**0install.yml**: Installing Podman required OS packages

**1prepare.yml**:
  - Creating podman networks
  - Applying limit when choosing explicit container via *podman_limited_containers*
  - Making sure the necessary folders for the container exist
  - We see logging into dockerhub as mandatory as they limit to 10 images per hour per IP since April 1st of 2025. Set `podman_dockerio_username` and `podman_dockerio_password`

**main.yml**:
  - Installing podman secrets and referencing further task files.

**2plugins.yml**:
  - Meta task that will delegate further to the specific plugin files, e.g. *plugin_psql.yaml*. This calls another role from MMN that has been modified to work with managing the configuration of a podman container.
  - For this to work you need to set what plugins shall be run on what container instances, here the psql plugin will be run for the psql0 podman container instance.
```yaml
podman_container_plugin_psql:
  - "psql0"
```
  - For detailed information for each plugin, look into the README of the corresponding role, for instance `ansible_psqlserver` for the plugin `psql`.
```yaml
podman_containers:
  - name: psql0 
    plugin: psql
    state: started
    [...]
```
**main.yml**
  - Creating containers with the *podman_containers* role.

**2plugins2.yml**
  - Some plugins require to run the plugin's role a second time as psql for example expects an empty data dir at first initialization. After the containers have been initialized, only then we can place the target configuration files.

**4post.yml**

Handling service state for the container. Possible state values for your container element definition:
- started
- present
- stopped
- absent
splitted into two variants:

  **systemd.yml**:
    - Install systemd service unit files and set correct state

  **procd.yml**:
    - OpenWrt init scripts and hotplug scripts

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
This will effectively put the secret into a plaintext file at `/run/secrets/
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

