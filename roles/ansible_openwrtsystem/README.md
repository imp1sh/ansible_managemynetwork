# imp1sh.ansible\_openwrt.ansible\_openwrtsystem

Example of how to define system parameter for a host:
```yaml
openwrt_system_hostname: "n300.demo.junicast.de"
openwrt_system_description: "n300 Routing Node"
openwrt_system_notes: "Zusätzliche Infos hier"`  
openwrt_system_maintainer: "Jochen Demmer <jochen@winteltosh.de>"
openwrt_system_timezone: "CET-1CEST,M3.5.0,M10.5.0/3"
openwrt_system_zonename: "Europe/Berlin"
openwrt_system_logsize: "32"
openwrt_system_ntp_server:
  - "2.nl.pool.ntp.org"
  - "2.de.pool.ntp.org"
openwrt_system_ntp_enable_server: 1
openwrt_system_ntp_use_dhcp: 0
```

For more detailed information please have a look at the official [OpenWrt system configuration docs](https://openwrt.org/docs/guide-user/base-system/system_configuration).

## Differences to stock OpenWrt
### Console login

The variable `openwrt_system_ttylogin` defaults to `1`, thus it is required to enter credentials in order to be able to get a prompt. So if you connect via KVM or serial, remember to have your password. This seems crucial to me in order to get a minimum amount of security around OpenWrt. If you set this variable to `0` it reverts back to the OpenWrt default.

### Kernel logging to console
Kernel error messages are prompted to STDERR in a stock OpenWrt. Since this can be overwhelmingly annoying this role defaults to disable this feature. If you would like to revert back to OpenWrt default, set `openwrt_system_kernellogonconsole` to `true`. 
When firewall logging is disabled expect the screen to be flooded

## Kernel Parameters
You can also set other kernel parameters with this role:

**Kernel parameter**: [net.netfilter.nf_conntrack_acct](https://ipset.netfilter.org/iptables-extensions.man.html)
Ansible variable: *openwrt_system_nf_conntrack_acct*

**Kernel parameter**: [net.netfilter.nf_conntrack_checksum](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_checksum*

**Kernel parameter**: [net.netfilter.nf_conntrack_max](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_max*
This value is quite important when you have plenty of parallel connections. A good example is NTP or torrent. In such cases you should adjust the value otherwise new connections will be stalled.

**Kernel parameter**: [net.netfilter.nf_conntrack_tcp_timeout_established](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_tcp_timeout_established*

**Kernel parameter**: [net.netfilter.nf_conntrack_udp_timeout](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_udp_timeout*

**Kernel parameter**: [net.netfilter.nf_conntrack_udp_timeout_stream](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
Ansible variable: *openwrt_system_nf_conntrack_udp_timeout_stream*
