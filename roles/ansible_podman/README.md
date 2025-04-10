# imp1sh.ansible_managemynetwork.ansible_podman
This role sets up podman containers, networks and secrets. It utilizes the official [podman community collection](https://docs.ansible.com/ansible/latest/collections/containers/podman/podman_container_module.html).

## Supported OSes
- Debian
- OpenWrt (planned)

## Supported Features
Supporting the following roles from the [containers.podman collection](https://galaxy.ansible.com/ui/repo/published/containers/podman/).
- podman_containers
- podman_secrets ([WiP](https://github.com/containers/ansible-podman-collections/issues/692))
- podman network
- Run not only all containers (default) but set a limited by entering the container name into `podman_limited_containers`

# Worflow
- Handling all the common podman stuff like:
**0install.yml**: Installing Podman required OS packages
**1prepare.yml**:
  - Creating podman networks
  - Applying limit when choosing explicit container via *podman_limited_containers*
  - Making sure the necessary folders for the container are in existance
  - We see logging into dockerhub as mandatory as they limit to 10 images per hour per IP since April 1st of 2025. Set `podman_dockerio_username` and `podman_dockerio_password`
**main.yml**:
  - Installing podman secrets
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
  - Some pluggins require to run the plugin's role a second time as psql for example expects an empty data dir at first initialization. After the containers have been initialized, only then we can place the target configuration files.
**4post.yml**
Handling service state for the container. Possible state values for your container element definition:
- started
- present
- stopped
- absent
splitted into two variants:
  **systemd.yml**:
    - controlling systemd so that there is a systemd-service unit file and that this service in the designated state
  **procd.yml**:
    - For OpenWrt

## Containers
It basically works like this. You define the variable `podman_containers`, see an example.
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
          3838393466353763663961323730618361336537643835360a346436623866383865623730353031
          37313263306531623133363364323830373137663038373835353731613261346465616431373364
          3266376139356537390a323338303237643065303335313464656536383735643833623231366335
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

## Plugins
This is supposed to work as a plugin system of sorts. The idea is to not only deploy a working container but also deploy the configuration for that very target application. The idea is to achieve an Infrastructure as Code (IaC) mode for this role.
Supported plugin:

| Plugin name | Related Ansible role | Description |
| - | - | - |
| psql | [imp1sh.ansible_managemynetwork.ansible_psqlserver](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_psqlserver) | |
| borgmatic | [imp1sh.ansible_managemynetwork.ansible_borgmatic](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_borgmatic) | |
| pdnsauth | [imp1sh.ansible_managemynetwork.ansible_pdnsauth](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_pdnsauth) | |

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
