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
