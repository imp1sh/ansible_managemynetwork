# imp1sh.ansible_managemynetwork.ansible_borgmatic

This role fully automates the setup process of [borg backup](https://www.borgbackup.org/), using [borgmatic](https://torsion.org/borgmatic/). Borgmatic is a wrapper for borg that makes several tasks much easier, for example backing up MySQL / MariaDB or PostgreSQL databases or integrating notifications.

Supported OS:
- Debian
- Container
- ~~FreeBSD~~ Cannot support it any more
- ~~Alpine~~ (May work but basically deprecated)
- ~~Arch~~ (May work but basically deprecated)
- ~~Fedora~~ (May work but basically deprecated)

Requirements:
- [imp1sh.ansible_managemynetwork.ansible_packages](https://wiki.junicast.de/en/junicast/docs/AnsibleManagemynetworkCollection/rolePackages)

This role supports running on Debian as well as in a container (tested on podman).
For container see also docs of the [imp1sh.ansible_managemynetwork.ansible_podman](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_openwrtpodman) role.
If running on normal OS this role installs borg / borgmatic via pip. The command will be `borgmatic_venv`. Using pip is the recommended way. If you don't want to use pip set `borgmatic_via_pip: false` and `apprise_via_pip: false` as well.

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
    format: "custom" # for seperate restore files, much easier to handle than one big dump file with all databases in it
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

## Repositories examples
Here's an example for a *hetzner* backup:
```yaml
borgmatic_repositories:
  u200000@u200000.your-storagebox.de:
    type: "ssh://"
    targetuser: u200000
    targethost: u200000.your-storagebox.de
    subdir: fsn1
    enabled: true
```
This one is for [borgbase - a really nice and affordable backup target storage provider](https://www.borgbase.com/). Have this role installed as well. [adhawkins.borgbase](https://github.com/adhawkins/ansible-borgbase). This role wil setup ssh keys and borgbase repos for you automatically.
```yaml
borgmatic_repositories:
  borgbase0:
    type: "borgbase"
    enabled: true
```

## Containermode

Instead of running borgmatic on the host itself it can also be run within a container. Set those vars:
```yaml
# Enable containermode
borgmatic_containermode: True
# Set the path for the crontab file
borgmatic_cronfile: "/mnt/cntr/unsynced/borgmatic/0/borgmatic.d/crontab.txt"
# Enable or disable cronjob with this
borgmatic_cronstate: "present"
# This is where the ssh keys will be put
borgmatic_sshdir: "/mnt/cntr/unsynced/borgmatic/0/ssh/"
# This is where borgmatic config will be put
borgmatic_confdir: "/mnt/cntr/unsynced/borgmatic/0/borgmatic.d/"
# This parameter is not container specific but this is the default mount point where you mount into your container so it will be backed up. Normally you don't have to give any other dir, just mount everything you want to backup into this dir in the container. Don't forget to define excludes based on this dir
borgmatic_srcdirs:
  - "/mnt/source"
```

Here's also an example of a podman definition so you can see how the mounting typically goes.
```yaml
podman_containers:
  - name: borgmatic_nasofden1
    state: started
    network: podmannetGUA
    # this is quite important so your repository carry a speaking name
    hostname: "{{ inventory_hostname }}"
    image: ghcr.io/borgmatic-collective/borgmatic
    volume:
      - "/mnt/cntr/unsynced/borgmatic/0/repository/:/mnt/borg-repository/"
      - "/mnt/cntr/unsynced/borgmatic/0/borgmatic.d/:/etc/borgmatic.d/"
      - "/mnt/cntr/unsynced/borgmatic/0/config/:/root/.config/borg/"
      - "/mnt/cntr/unsynced/borgmatic/0/ssh/:/root/.ssh/"
      - "/mnt/cntr/unsynced/borgmatic/0/root/:/root/.local/state/borgmatic/"
      - "/mnt/cntr/unsynced/:/mnt/source/:ro"
      # I added those because borgmatic is no more running on the host but I also want those host's folders backed up
      - "/etc/:/mnt/source/etc/:ro"
      - "/opt/:/mnt/source/opt/:ro"
      - "/home/:/mnt/source/home/:ro"
      - "/root/:/mnt/source/root/:ro"
    env:
      TZ: "Europe/Berlin"
```

```
When running borgmatic in a container you need to run the `ansible_podman` role and enable the borgmatic plugin. The `ansible_podman` role then will also run the `ansible_borgmatic` role and take care of everything. This is how you enable the plugin for the container borgmatic0. I keep naming the container for backup the same on every host so I can define this on a group var scope in ansible
```
podman_container_plugin_borgmatic:
  - "borgmatic0"
```
This is an example of calling the podman role. It will also setup borgmatic within that very run so no need to call the borgmatic role directly.
```
ansible-playbook playbooks/podman.yml -l nas1.libcom.de -e podman_limited_containers=borgmatic0 --ask-vault-pass
```

This is my playbook file:
```yaml
- name: "MMN Podman Role"
  hosts: tags_podman
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_podman
```
Those vars I typically define on a group scope level, so this is the same for every host that will run borgmatic in a container.

```yaml
# what is the container name (needed for restarts etc.)
borgmatic_containername: "borgmatic0"
# Enable containermode so when running this role on a host in containermode won't break thins
borgmatic_containermode: True
# the cronfile is to be expected in a specific dir
borgmatic_cronfile: "/mnt/cntr/unsynced/borgmatic/0/borgmatic.d/crontab.txt"
borgmatic_cronstate: "present"
# here the ssh keys and stuff are in
borgmatic_sshdir: "/mnt/cntr/unsynced/borgmatic/0/ssh/"
# config directory, also cron file normaly is put here
borgmatic_confdir: "/mnt/cntr/unsynced/borgmatic/0/borgmatic.d/"
# name the container the borg runs in
borgmatic_containername: "borgmatic0"
```


## Scheduling

Backups are scheduled via systemd timer by default. When running borgmatic in containermode it will use cron. The time when it will run will be daily randomized between 1 and 6 in the morning. You can override the time directly. It's recommended to define static values, otherwise each ansible run new timers will be randomized which might be unwanted.
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

## Restore
There are multiple approaches. You could create another container only fore restoring that has a restore target RW mounted. You could as well just mount the /mnt/source RW instead of readonly and then use common borgmatic commands within the container in order to restore. Another options to add a bind mount volume to the existing container and restore into that directory.

For a hint how to define ad dedicated restore container, have a look into the ansible_podman docs. Just don't forget to stop the restore container when finished. Otherwise cron jobs might conflict with the actual backup container.
