# imp1sh.ansible_managemynetwork.ansible_borgmatic

This role fully automates the setup process of [borg backup](https://www.borgbackup.org/), using [borgmatic](https://torsion.org/borgmatic/). Borgmatic is a wrapper for borg that makes several tasks much easier, for example backing up MySQL / MariaDB or PostgreSQL databases or integrating notifications.

Supported OS:
- Debian
- Container
- ~~FreeBSD~~ Cannot support it any more
- ~~Alpine~~ (May work but basically deprecated)
- ~~Arch~~ (May work but basically deprecated)
- ~~Fedora~~ (May work but basically deprecated)

> This role supports running on Debian as well as on a a container (tested on podman).
> For container see also docs of the [imp1sh.ansible_managemynetwork.ansible_podman](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_openwrtpodman) role.
> If running on normal OS this role installs borg / borgmatic via pip. The command will be `borgmatic_venv`. This is the recommended way to use pip. If you don't want to use pip set `borgmatic_via_pip: false` and `apprise_via_pip: false` as well.

Requirements  (mandatory):
- [imp1sh.ansible_managemynetwork.ansible_packages](https://wiki.junicast.de/en/junicast/docs/AnsibleManagemynetworkCollection/rolePackages)
Recommendations (optional):
- [imp1sh.ansible_managemynetwork.ansible_apprise](https://wiki.junicast.de/en/junicast/docs/AnsibleManagemynetworkCollection/roleApprise)

When using **ssh** as backend this role can also handle the necessary key based tasks, so Ansible needs access to the backup target machine as well.

## Configuration
Here is a sample config for a case using SSH based authentication.

```yaml
# better encrypt your passphrase!
borgmatic_encpassphrase: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          62373162376264353131353664303738303866346532303966616261336366306461653234363164
          [...]
          61373138303266333139

borgmatic_compression: "zstd" # zstd more efficient but slightly slower than default lzo

# Source directories, what to backup.
borgmatic_srcdirs:
  - "/mnt/source"

# Then again you might want to exlude stuff again
borgmatic_excludepatterns:
  - "/mnt/source/elasticsearch/1/index"
  - "/mnt/source/loki/rx1/data/chunks"
  - "/mnt/source/prometheus/libcom/data"
  - "/mnt/source/kiwix/0/data"

# How long you wanto to keep your backup (retention)
borgmatic_keepdaily: 9
borgmatic_keepweekly: 2
borgmatic_keepmonthly: 2
# The range in which between is randomized you can define
borgmatic_timer_hourrange_start: 2
borgmatic_timer_hourrange_end: 4

# apprise integration is being overhauled currently
borgmatic_apprise: true
borgmatic_apprise_user: "notify"
borgmatic_apprise_password: "secret"
borgmatic_apprise_hostname: "matrix.libcom.de"
borgmatic_apprise_matrixroom: "!uRjlIhFDS39DSRztLY:libcom.de"
borgmatic_hooks_on_error:
  - "/usr/local/bin/apprise_borgmatic.sh \"{configuration_filename}\" \"{repository}\" \"{error}\""

# you can also include databases, e.g. postgresql
borgmatic_postgresdbs:
  - name: "all"
    hostname: "psql0"
    username: "postgres"
```
It would be advisable to set the backup target in a group var for your site.
```yaml
borgmatic_repositories:
  backupuser@target0:
    type: "ssh://"
    targetuser: backupuser
    targethost: target0.example.com
    subdir: myhost
    enabled: true
  backupuser@target1:
    type: "ssh://"
    targetuser: backupuser
    targethost: target1.example.com
    subdir: somedir
    enabled: false
```
If you don't want to manage the ssh keys maybe because you just lack control over backup target machine, set
```yaml
borgmatic_ssh_manage: False
```


## Container specific settings
```yaml
# what is the container name (needed for restarts etc.)
borgmatic_containername: "borgmatic_cntr-ofden1"
# the cronfile is to be expected in a specific dir
borgmatic_cronfile: "/mnt/cntr/unsynced/borgmatic/0/borgmatic.d/crontab.txt"
borgmatic_cronstate: "present"
# here the ssh keys and stuff are in
borgmatic_sshdir: "/mnt/cntr/unsynced/borgmatic/0/ssh/"
# config directory, also cron file normaly is put here
borgmatic_confdir: "/mnt/cntr/unsynced/borgmatic/0/borgmatic.d/"
```


## Schedule (non Container)
Backups are scheduled via systemd timer by default. The time when it will run will be daily randomized between 1 and 6 in the morning. You can override the time directly. It's recommended to define static values, otherwise each ansible run new timers will be randomized which might be unwanted.
```yaml
borgmatic_timer_hour: 1
borgmatic_timer_minute: 3
```
or define another range within which the time will be randomized
```yaml
borgmatic_timer_hourrange_start: 1
borgmatic_tiimer_hourrange_end: 6
borgmatic_tiimer_minuterange_start: 1
borgmatic_tiimer_minuterange_end: 59
```
You can also define the OnCalender value directly by setting the var `borgmatic_timer_schedule`. [Look Arch wiki](https://wiki.archlinux.org/title/Systemd/Timers#Realtime_timer) for more information on the format.
If you don't want to have the systemd job managed via the role, set
```yaml
borgmatic_systemd_manage: False
```

## Schedule (Container)

The container uses cron instead. You can still use the same `borgmatic_timer_*` variables though in order to define execution timers. When you change the cron timer the container will restart in order to adjust to the new settings.

## Apprise notification
Since borgmatic 1.8.3 [apprise](https://github.com/caronc/apprise) integration has gotten much better so my old method is now deprecated.
It is a good idea to get notified when something goes wrong during the backup process.
Just define a dict var carrying the apprise parameters
```yaml
borgmatic_apprise:
  services:
    - url: "matrixs://username:{{ borgmatic_apprise_password }}@matrix.example.com/!roomid
      label: "Matrix"
      fail:
        title: "Borgmatic backup fail event"
        body: "Failed borgmatic backup on host {{ inventory_hostname }}"
      states:
        - fail
borgmatic_apprise_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          33336534653530626531356330616333343135363831396632303133633430643430636332666531
          [...]
          6137
```
The roomid might look something like this: zEWDASjFsFzJwNIhN:envs.net"
