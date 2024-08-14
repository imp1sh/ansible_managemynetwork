# imp1sh.ansible_managemynetwork.ansible_restic
This role sets up restic backup for your ansible node. This role will try to install the ssh public key to the target backup machine (when manage_ssh: true), so ideally it is managed by ansible, too.

> Since version 0.4.1 there was a major overhaul of this role. It supports defining multiple repositories now, so it can be backed up to multiple locations.
{.is-warning}

## Sample config

```yaml
restic_backups:
  - name: "wasabi"
    state: "present"
    repotype: "s3:https"
    targethost: "s3.eu-west-2.wasabisys.com"
    targetsubdir: "forelle" #this is the bucket in s3
    aws_access_key_id: "youraccesskey"
    aws_secret_access_key: "yourverysecretsecretkey"
  - name: "backup_to_siteA"
    state: "absent"
    repotype: "sftp"
    targetsubdir: "SiteX"
    targethost: "myhost.onsitea.com"
    sshkey_user: "backupuser"
    authuser: "backupuser"
    manage_ssh: true
    includes:
      - "/etc"
      - "/root"
  - name: "backup_to_borgbase"
    state: "present"
    repotype: "rest:https"
    authuser: "secretusername"
    authpass: "secretpassword"
    targethost: "username.repo.borgbase.com"
    includes:
      - "/etc"
      - "/root"
```


> OpenWrt doesn't create huge amounts of data. You can very well use the free service of [borgbase] (https://www.borgbase.com/). They offer superb service for backing up your data either via borg or restic, which are both one of the best tools for encrypted backup.

## Fine tune your backup

Optionally you can define some settings per backup list item with the following attributes in a `restic_backups` list element:
- keepdaily
- keepweekly
- keepmonthly

You define one encryption passphrase for all targets via:

```yaml
restic_encpassphrase: "yoursupersecretandlongpassphrase"
```
or you can define it on a target level. Target level definition always preceeds global config setting.

Regarding the cron timings, you can use the defaults. This will result in randomized times not earlier than 01:01h and not later than 06:59h. You can modify the range by overriding the defaults in:
```yaml
restic_cron_hourrange_start: 1
restic_cron_hourrange_end: 6
restic_cron_minuterange_start: 1
restic_cron_minuterange_end: 59
```
If you don't want it to be random, you need to either set e.g.

```yaml
restic_cron_hour: 3
restic_cron_minute: 34
```

or set it as an attribute of a list item of `restic_backups`
- `cron_hour: 9`
- `cron_minute: 0`

The same is true for the pruning mechanism, using the same variables s/cron/prune/.
For OpenWrt this restic role will automatically create a cron job, that writes a list of all installed packages to `/etc/config/installed.packages` every day at midnight.

## Typical commands
### List snapshots
```
restic -p /etc/resticpassword_<<your_destination>> snapshots -r sftp:backupuser@<<target_hostname>>:./<<subfolder>> /<<myhostname>>
```
e.g.
```
restic -p /etc/resticpassword_to_datacenter1 snapshots -r sftp:backupuser@backup1.example.com:./subfolder1/firewall1.example.com
```

### Restore
```
restic -p /etc/resticpassword_<<your_destination>> -r sftp:backupuser@<<target_hostname>>>:./<<subfolder>>/<<myhostname>> restore <<latest oder snapshot id>> --target /tmp
```
e.g.
```
restic -p /etc/resticpassword_to_datacenter1 -r sftp:backupuser@backup1.example.com:./subfolder1/firewall1.example.com restore ae2bd94c --target /tmp
```
instead of a specific snapshot you can just say `latest`.
```
restic -p /etc/resticpassword_to_datacenter1 -r sftp:backupuser@backup1.example.com:./subfolder1/firewall1.example.com restore latest --target /tmp
```
More information about restic can be found on their [homepage](https://restic.net/).

### Mount backup
This will mount the repository to `/mnt/tmp`. Within the mount you can decide which backup date to use.
```
restic -p /etc/resticpassword_<<your_destination>> -r sftp:backupuser@<<target_hostname>>>:./<<subfolder>>/<<myhostname>> mount /mnt/tmp
```
