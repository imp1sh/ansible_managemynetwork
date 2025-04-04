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
  - Calls all the diffent plugin files, e.g. *plugin_psql.yaml*. This calls another role from MMN that has been modified to work with managing the configuration of a podman container.
  - For this to work in each podman_containers element you need to set what plugins to use:
```yaml
podman_container_plugins:
  - "psql"
```
  - For detailed information for each plugin, look into the README of the corresponding role, e.g. `ansible_psqlserver` for the plugin `psql`.
```
podman_containers:
  - name: psql0 
    plugin: psql
    state: started
    network: podmannetGUA
    ip: 10.10.151.74
    ip6: 2001:67c:fb8:1002::59
    image: docker.io/postgres:17.4-bookworm
```
**main.yml**
  - Creating containers with the *podman_containers* role.
**2plugins2.yml**
  - Some pluggins require to run the plugin's role a second time as psql for example expects an empty data dir at first initialization. After the containers has been initialized only then we can place the target configuration files.
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
| psql | imp1sh.ansible_managemynetwork.ansible_psqlserver | |
 
