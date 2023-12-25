# imp1sh.ansible_managemynetwork.ansible_borgmatic

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_borgmatic)

This role fully automates the setup process of [borg backup](https://www.borgbackup.org/), using [borgmatic](https://torsion.org/borgmatic/). Borgmatic is a wrapper for borg that makes several tasks much easier, for example backing up MySQL / MariaDB or PostgreSQL databases.

Supported OS:
- Debian
- Ubuntu (best effort)
- FreeBSD (best effort)
- ~~Alpine~~ (May work but basically deprecated)
- ~~Arch~~ (May work but basically deprecated)
- ~~Fedora~~ (May work but basically deprecated)


> This role used to install borg / borgmatic via pip which is deprecated. You might try this method but generally speaking you should set `borgmatic_via_pip: false` and `apprise_via_pip: false`
{.is-warning}

Requirements:
- [imp1sh.ansible_managemynetwork.ansible_packages](https://wiki.junicast.de/en/junicast/docs/AnsibleManagemynetworkCollection/rolePackages)
- [imp1sh.ansible_managemynetwork.ansible_apprise](https://wiki.junicast.de/en/junicast/docs/AnsibleManagemynetworkCollection/roleApprise) (optional)

When using **ssh** as backend this role will also handles the necessary key based tasks, so Ansible needs access to the backup target machine.

## SSH target
Here is a sample config. This is from group_vars/all.yml so every host has the same config. 

```yaml
borgmatic_compression: "zstd"
borgmatic_keepdaily: 9
borgmatic_keepweekly: 2
borgmatic_keepmonthly: 2
borgmatic_cron_hourrange_start: 2
borgmatic_cron_hourrange_end: 4
borgmatic_apprise: true
borgmatic_apprise_user: "notify"
borgmatic_apprise_password: "secret"
borgmatic_apprise_hostname: "matrix.libcom.de"
borgmatic_apprise_matrixroom: "!uRjlIhFDS39DSRztLY:libcom.de"
borgmatic_hooks_on_error:
  - "/usr/local/bin/apprise_borgmatic.sh \"{configuration_filename}\" \"{repository}\" \"{error}\""
```
You an then set the encryption passphrase individually per host like this:
```yaml
borgmatic_encpassphrase: "yoursupersecurepassphrase"
```
It would be advisable to set the backup target in a group var for your site.
```yaml
borgmatic_repositories:
  - "ssh://backupuser@backuptargetsystem1.libcom.de/./subfoldername/{{ inventory_hostname }}"
borgmatic_sshkey_user: "backupuser"
borgmatic_sshkey_targethost: "backuptargetsystem1.libcom.de"
```
If you don't want to manage the ssh key port maybe because you just cannot integrate the backup target machine into Ansible, set
```yaml
borgmatic_ssh_manage: False
```

## Schedule
Backups are scheduled via cron. The time when it will run will be randomized between 1 and 6 in the morning. You can override the time directly
```yaml
borgmatic_cron_hour: 1
borgmatic_cron_minute: 3
```
or define another range within which the time will be randomized
```yaml
borgmatic_cron_hourrange_start: 1
borgmatic_cron_hourrange_end: 6
borgmatic_cron_minuterange_start: 1
borgmatic_cron_minuterange_end: 59
```
If you don't want to have the cron job managed via the role, set
```yaml
borgmatic_cron_manage: False
```

## Apprise notification
It is a good idea to get notified when something goes wrong during the backup process. That's why there is optional apprise support.
Set `borgmatic_apprise` to `true` and [apprise](https://github.com/caronc/apprise) will be setup. Apprise is IMHO the best notification wrapper currently. It supports an incredible number of services to get you notified. My Ansible implementation though currently only supports notifications via [Matrix chat](https://matrix.org/). (Pull requests welcome).

For matrix notification via apprise to work you would also want to set those variables
```
tags_allhosts.yml:borgmatic_apprise: true
tags_allhosts.yml:borgmatic_apprise_user: "notify"
tags_allhosts.yml:borgmatic_apprise_password: "secretpassword"
tags_allhosts.yml:borgmatic_apprise_hostname: "matrix.libcom.de"
tags_allhosts.yml:borgmatic_apprise_matrixroom: "!uRQiJBDsdfjiJHJKHuSDFLY:libcom.de"
```

