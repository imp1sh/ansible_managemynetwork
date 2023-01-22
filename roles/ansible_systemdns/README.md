# ansible_systemdns
Part of nftwall. Lets you set very basic DNS settings in /etc/resolv.conf.
This is an example how a how variables need to be set in order to function:
```
dnsservers:
  - "2.167.12.60"
  - "2.167.12.60"
  - "2001:1234:100:1020:53::2"
  - "2001:1234:100:1020:53::1"
domainsearch: "demo.ansible.com"

```
domainsearch is optional

This is not suited for systems using NetworkManager.
