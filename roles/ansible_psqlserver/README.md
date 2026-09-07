# imp1sh.ansible_managemynetwork.ansible_psqlserver
This role will setup postgresql server.

## OS support
- Debian

## Usage
Define databases like this:
```yaml
psqlserver_instances:
  main: 
    listenips: "*"
    max_connections: "500"
    wal_level: "replica"
    wal_log_hints: "on"
    max_wal_senders: "5"
    wal_keep_size: "8192"
    max_wal_size: "12GB"
    dbs:
      - dbname: "linkwarden0"
      - dbname: "immich0"
    roles:
      - rolename: "linkwarden_user"
        password: !vault |
              $ANSIBLE_VAULT;1.1;AES256
              [...]
              6633366337333634300a623966386430323637323931323633626330393534656366373335323961
              3463
        db: "linkwarden0"
        priv: "ALL"
      - rolename: "immich0_user"
        password: !vault |
              $ANSIBLE_VAULT;1.1;AES256
              [...]
              6331373331383333390a343239393163303234393466306234626463666537323566656331613666
              3663
        db: "immich0"
        priv: "ALL"
    hba:
      - dest: "{{ psqlserver_hbafile }}"
        contype: "host"
        users: "linkwarden_user"
        source: "{{ nb_vms['cntr-ofden1.libcom.de']['primary_ip6'] | ansible.utils.ipaddr('address') }}"
        databases: "linkwarden0"
        method: "md5"
        state: "present"
      - dest: "{{ psqlserver_hbafile }}"
        contype: "host"
        users: "immich0_user"
        source: "{{ nb_vms['cntr-ofden1.libcom.de']['primary_ip6'] | ansible.utils.ipaddr('address') }}"
        databases: "immich0"
        method: "md5"
        state: "present"
```
Having more than one instance is untested for non podman environments.

## Containermode
This very role will be called by ansible_podman when the plugin is activated (see ansible_podman role for documentation). The ansible_podman role will set the variable `psqlserver_containermode` to *true*. In this mode this ansible_psqlserver role will setup a postgresql server in a podman container.

> **Systemd unit name:** the `restart postgres container` handler targets
> `container-<name>` by default, or `<name>` when the podman role is running in
> Quadlet mode (`podman_use_quadlet: true`). This is handled automatically; no
> inventory change is needed. If you hit a constant shutdown/restart loop of the
> `container-<name>.service` unit after recreating a container, switch the host
> to Quadlet (see the `ansible_podman` README) — the legacy
> `podman generate systemd` path bakes the container id into the unit and goes
> stale on every recreate.

You can imagine with containers you might want to have more than one postgresql instance running on your podman host. To account for that this role will work with dictionaries so you can define a flexible amount of databases for your target host.

This is how a container definition might look like (excerpt).
```yaml
podman_containers:
  - name: psql0
    plugin: psql  
    state: started
    network: podmannetGUA
    [...]
```

> ⚠️ Make sure to name the dictionary key the same as the podman container name from ansible_podman role (see above).
This is an example psqlserver instance definition.

```yaml
psqlserver_instances:
  psql0:
    configpath: "/mnt/cntr/unsynced/psql/0/data/"
    listenips: "*"
    max_connections: "500"
    wal_level: "replica"
    wal_log_hints: "on"
    max_wal_senders: "5"
    wal_keep_size: "8192"
    max_wal_size: "12GB"
      #hbafile: "/mnt/cntr/unsynced/psql/0/data/pg_hba.conf"
    dbs:
      - dbname: "linkwarden0"
    hba:
      - dest: "/mnt/cntr/unsynced/psql/0/data/pg_hba.conf"
        contype: "host"
        create: true
        users: "linkwarden_user"
        source: "{{ nb_vms['cntr-ofden1.libcom.de']['primary_ip6'] | ansible.utils.ipaddr('address') }}"
        databases: "linkwarden0"
        method: "md5"
        state: "present"
    initscripts:
      - name: "1_pdns_init.sh"
        targetpath: "/mnt/cntr/unsynced/psql/0/init"
        content: |
          #!/usr/bin/env bash
          set -e
          psql -U $POSTGRES_USER -c "CREATE ROLE replication WITH REPLICATION LOGIN PASSWORD '$(cat /run/secrets/psql0_replicationuser_password)';"
          psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
              CREATE USER pdns;
              CREATE DATABASE pdns;
              GRANT ALL PRIVILEGES ON DATABASE pdns TO pdns;
          EOSQL
```

## PostgreSQL 18+ container layout

Starting with the upstream `postgres:*-trixie` / `*-bookworm` images based on
PostgreSQL 18, the Docker entrypoint switched to the Debian
`pg_ctlcluster`-style on-disk layout ([docker-library/postgres#1259]). The
practical consequences for this role are:

- Database data lives in a **major-version-specific subdirectory**,
  `/var/lib/postgresql/<major>/<cluster>/` inside the container (cluster name
  defaults to `docker`), instead of the flat `/var/lib/postgresql/data/`.
- Configuration files (`postgresql.conf`, `pg_hba.conf`, `pg_ident.conf`) are
  read from `/etc/postgresql/<major>/<cluster>/` inside the container, **not**
  from the data directory.

[docker-library/postgres#1259]: https://github.com/docker-library/postgres/pull/1259

### What the role does for you

The role is version-agnostic as of this update:

- Reloads are issued via `SELECT pg_reload_conf()` over the role's temporary
  socat port-forward (`127.0.0.1:55432`), authenticating with the instance's
  `password_admin`. No hardcoded `pg_ctl` binary path or data-directory path is
  used, and no in-container `psql` invocation is required (the PG 18 Debian
  image's `pg_ctlcluster` layout breaks default-socket discovery for exec'd
  `psql`). This works on PostgreSQL 13 through 18+ and on both Alpine and
  Debian-based images.
- The `postgresql_pg_hba` task defaults `create: true`, so pointing `hba[].dest`
  at a fresh config-mount location will create the file instead of failing.
- Parent directories of each `hba[].dest` are ensured automatically.

### What you must change in host_vars for PG 18+

Because volume mounts are owned by the `ansible_podman` container definition
(not this role), migrating a host to PG 18+ requires adjusting the container's
`volume` list and the corresponding `psqlserver_instances` paths:

1. **Mount the data parent** so the version subdir can live underneath it:
   ```yaml
   volume:
     - "/mnt/cntr/unsynced/psql/0/:/var/lib/postgresql"
   ```
   (was `…/0/data/:/var/lib/postgresql/data/` pre-18)
2. **Mount a config directory** over the location the entrypoint reads:
   ```yaml
   volume:
     - "/mnt/cntr/unsynced/psql/0/conf/:/etc/postgresql/{{ psqlserver_version }}/{{ psqlserver_clustername }}/"
   ```
3. **Repoint role paths** so the role writes where the server reads:
   ```yaml
   psqlserver_instances:
     psql0:
       configpath: "/mnt/cntr/unsynced/psql/0/conf/{{ psqlserver_version }}/{{ psqlserver_clustername }}"
       hbafile: "/etc/postgresql/{{ psqlserver_version }}/{{ psqlserver_clustername }}/pg_hba.conf"
       datadir: "/var/lib/postgresql/{{ psqlserver_version }}/{{ psqlserver_clustername }}"
       hba:
         - dest: "/mnt/cntr/unsynced/psql/0/conf/{{ psqlserver_version }}/{{ psqlserver_clustername }}/pg_hba.conf"
           ...
   ```

The opt-in variables `psqlserver_version` (default `"18"`) and
`psqlserver_clustername` (default `"docker"`) are available in container mode
to help construct these paths consistently. They are not referenced by the role
internally, so pre-PG18 inventories that do not use them keep working unchanged.

### Migrating an existing PG ≤17 cluster to PG 18

A major-version bump requires a real upgrade (`pg_upgrade` or dump/restore),
not just an image tag change. The role intentionally performs no data
migration; orchestrate `pg_upgrade --link` or a logical dump/restore outside the
role, then point the inventory at the new layout described above.

# TODO
- Install required psycopg2 on target host
