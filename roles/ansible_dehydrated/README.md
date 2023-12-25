# imp1sh.ansible_managemynetwork.ansible_dehydrated

This role fetches Letsencrypt certificates for you. Dehydrated does it in standalone mode so it simply fetches certs. Via hooks of course you can restart services after they were fetched.

This role is mainly tested in DNS challenge environments but also HTTP. If you want to use testing CA you would need to override the `dehydrated_ca` var.

Requirements:
- [imp1sh.ansible_managemynetwork.ansible_packages](https://wiki.junicast.de/en/junicast/docs/AnsibleManagemynetworkCollection/rolePackages)

Supported OSes:
- Debian
- Ubuntu (best effort)
- FreeBSD (best effort)
- ~~Alpine~~ (might work but basically is deprecated)

ansible_dehydrated will install curl and dehydrated via package manager. It will further install a cron job for automatic renewal. You need to define a list of domains that dehydrated shall fetch certificates for. If you need multiple fqdn in one cert, just put them in one line:
```yaml
dehydrated_domains:
  - "test.example.com"
  - "testing.com www.testing.com"
```


Example DNS challenge:
```yaml
dehydrated_challengetype: "dns-01"
dehydrated_hookchain: "yes"
dehydrated_pdnshost: "https://apiendpoint.example.com"
dehydrated_pdnskey: "yoursecretAPIkey"
dehydrated_hook: "{{ dehydrated_basedir }}/pdns_api.sh"
```

Example HTTP challenge:
```yaml
dehydrated_users_groupadd:
  - "www-data"
dehydrated_hook: "{{ dehydrated_basedir }}/nginxhook.sh"
dehydrated_wellknown: "/usr/local/www/dehydrated"
dehydrated_challengetype: "http-01"
```
This of course requires that your webserver is configured for http challenge support (.well-known).

