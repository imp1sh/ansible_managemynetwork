# # imp1sh.ansible_managemynetwork.ansible_nsupdate_bash

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_nsupdate_bash)

[nsupdate_bash](https://gitlab.com/junialter/nsupdate_bash) is a small script to update an AAAA record via nsupdate command (as in [rfc 2136](https://datatracker.ietf.org/doc/html/rfc2136)).
This role deploys a cronjob that updates the DNS record in case a host gets a new IP.

In my case I tag hosts in netbox to nsupdate_bash for the role, e.g.:

```yaml
---
- name: Run nsupdate_bash
  hosts: tags_nsupdate_bash
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_nsupdate_bash
```

Then I define the vars on a group level so all I need to do is tag a host in netbox to nsupdate_bash in order for the host to get rolled out the cron job.

This is how I define my vars for a site, as all attributes stay the same basically.

```yaml
nsupdate_bash_cronjobs:
  - server: "{{ nsupdate_bash_server }}"
    state: "present"
    zone: "{{ nsupdate_bash_zone }}"
    hostname: "{{ ansible_hostname }}.{{ nsupdate_bash_zone }}"
    keyfile: "{{ nsupdate_bash_keyfile }}"
    keyalgo: "{{ nsupdate_bash_keyalgo }}"
    keyname: "{{ nsupdate_bash_keyname }}"
    keysecret: "{{ nsupdate_bash_keysecret }}"
    ttl: "{{ nsupdate_bash_ttl }}"
    grepstring: "2a01:4dd0"
    timeout: "{{ nsupdate_bash_timeout }}"
    updateinterval: "{{ nsupdate_bash_updateinterval }}"
nsupdate_bash_server: "nsupdate.libcom.de"
nsupdate_bash_updateinterval: 5 # in minutes, will result in cron: */5
nsupdate_bash_zone: "lpv4.com"
nsupdate_bash_keyfile: "/usr/local/etc/mainjochen.key"
nsupdate_bash_keyalgo: "hmac-sha512"
nsupdate_bash_keysecret: "yourverysecurekeysecretwhichlooksdifferenttothis"
nsupdate_bash_keyname: "mainjochen"
nsupdate_bash_ttl: 60
nsupdate_bash_timeout: 5
```

## DNS Round Robin
If you have multiple AAAA records for DNS Round Robin you can add a *grepstring* to your cronjob dict item.
```yaml
nsupdate_bash_cronjobs:
  - server: "{{ nsupdate_bash_server }}"
    grepstring: "2a01:4fe:a33:"
    state: "present"
    zone: "{{ nsupdate_bash_zone }}"
    hostname: "{{ ansible_hostname }}.{{ nsupdate_bash_zone }}"
    keyfile: "{{ nsupdate_bash_keyfile }}"
    keyalgo: "{{ nsupdate_bash_keyalgo }}"
    keyname: "{{ nsupdate_bash_keyname }}"
    keysecret: "{{ nsupdate_bash_keysecret }}"
    ttl: "{{ nsupdate_bash_ttl }}"
    grepstring: "2a01:4dd0"
    timeout: "{{ nsupdate_bash_timeout }}"
    updateinterval: "{{ nsupdate_bash_updateinterval }}"
```

If a found AAAA record matches this string it will not be touched. This way you can make sure the right record will only be updated. Currently there is only support for up to two AAAA records.
