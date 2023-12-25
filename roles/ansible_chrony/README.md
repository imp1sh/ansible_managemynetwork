# imp1sh.ansible_managemynetwork.ansible_chrony

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_chrony)

This role installs and configures chrony either in client or in server mode. When in client mode it will also remove time sync components that maybe come from systemd (systemd-timesyncd).

Requirements:
- [imp1sh.ansible_managemynetwork.ansible_packages](https://wiki.junicast.de/en/junicast/docs/AnsibleManagemynetworkCollection/rolePackages)

## Server
To run it as a server a simple configuration suffices like:
```yaml
chronyd_config_allowfroms:
  - "0.0.0.0/0"
  - "::/0"
```

## Client

An example client config:
```yaml
chronyd_config_servers:
  - name: "ntpserver.example.de"
    options: "prefer"
chronyd_config_pools:
  - name: "2.de.pool.ntp.org"
    options: "iburst"
  - name: "2.nl.pool.ntp.org"
    options: "iburst"
  - name: "2.be.pool.ntp.org"
```

## Config options

The avaiable config options correspond to the chrony options.

```
chronyd_config_servers
chronyd_config_pools
chronyd_config_peers
chronyd_config_refclocks
chronyd_config_allowfroms
chronyd_config_denyfroms
chronyd_config_initstepslew
chronyd_config_corrtimeratio
chronyd_config_fallbackdrift
chronyd_config_leapsecmode
chronyd_config_leapsectz
chronyd_config_makestep
chronyd_config_maxchange
chronyd_config_maxclockerror
chronyd_config_maxdrift
chronyd_config_maxupdateskew
chronyd_config_maxslewrate
chronyd_config_tempcomp
chronyd_config_bindaddress
chronyd_config_broadcast
chronyd_config_clientloglimit
chronyd_config_noclientlog
chronyd_config_local
chronyd_config_port
chronyd_config_ratelimit
chronyd_config_smoothtime
chronyd_config_bindcmdaddress
chronyd_config_cmdallow
chronyd_config_cmddeny
chronyd_config_cmdport
chronyd_config_cmdratelimit
chronyd_config_hwclockfile
chronyd_config_rtcautotrim
chronyd_config_rtcdevice
chronyd_config_rtcfile
chronyd_config_rtconutc
chronyd_config_rtcsync
chronyd_config_log
chronyd_config_logbanner
chronyd_config_logchange
chronyd_config_logdir
chronyd_config_mailonchange
chronyd_config_keyfile
chronyd_config_lock_all
chronyd_config_pidfile
chronyd_config_sched_priority
chronyd_config_sched_user
chronyd_config_includedir
```
