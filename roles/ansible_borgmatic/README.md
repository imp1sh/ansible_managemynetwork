ansible_borgmatic
=========

sets up borgmatic borg backup wrapper

Requirements
------------

One of those Operating Systems:
* FreeBSD
* Debian
* Ubuntu
* Alpine
* Fedora

Role Variables
--------------

Passphrase for encryption
```
borgmatic_encpassphrase: "yoursupersecurepassphrase1234567890"
```

Default compression is lz4, overwrite like this.
```
borgmatic_compression: "zstd"
```
Setup retention if you don't like the default of just keeping 7 dailies.
```
borgmatic_keepdaily: 9
borgmatic_keepweekly: 2
borgmatic_keepmonthly: 2
```
Set up a target where to send the backups to:
```
borgmatic_repositories:
  - "backupuser@targethost.example.domain:{{ ansible_fqdn }}"
```
or with subfolder at the target:
```
borgmatic_repositories:
  - "backupuser@targethost.example.domain:subfolder/{{ ansible_fqdn }}"
```
SSH settings are also being managed by this role, thus needing those variables on top of the repository variable.
```
borgmatic_sshkey_user: "backupuser"
borgmatic_sshkey_targethost: "targethost.example.com"
```
The borg backup target host needs to be managed by ansible, too.

This is how you define src directories:
```
borgmatic_srcdirs:
  - "/etc"
  - "/opt"
  - "/home"
  - "/root"
```
You can setup exclude patterns, just an ez example:
```
borgmatic_excludepatterns:
  - "/home/userx/.local/share/"
```

If you don't want the role to manage SSH:
```
borgmatic_ssh_manage: False
```

If you don't want the role to manage CRON:
```
borgmatic_cron_manage: False
```
By default CRON is being setup in a range between 1st and 6th hour, 1st and 59th minute, adjustable with e.g.:
```
borgmatic_cron_hourrange_start: 4
borgmatic_cron_hourrange_end: 9
borgmatic_cron_minuterange_start: 34
borgmatic_cron_minuterange_end: 51
```

If you want to integrate Postgresql into backup:
```
borgmatic_postgresdbs:
  - name: "DB1"
    username: "postgres"
  - name: "DB2"
    username: "postgres"
```
If you just want all databases to be included:
```
borgmatic_postgresdbs:
  - name: "all"
    username: "postgres"
```
Further options for DB connection:
* hostname
* port
* format
* ssl_mode
* ssl_cert
* ssl_key
* ssl_root_cert
* ssl_crl

Dependencies
------------

none

Example Playbook
----------------

I suggest to combine hosts that need backup by group, here borgmatic:

- hosts: borgmatic
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_borgmatic

Role naming depends on how you install the role / collection.

License
-------

BSD

Author Information
------------------

Jochen Demmer 2021
