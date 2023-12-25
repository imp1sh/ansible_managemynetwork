# imp1sh.ansible_managemynetwork.ansible_openwrttinyproxy

This ansible role manages tinyproxy for OpenWrt. A minimalistic configuration is to just use this role. The default values will setup and make basic configuration.
For a more pracital example you can set some variables:

```yaml
openwrt_tinyproxy_filterdefaultdeny: "1"
openwrt_tinyproxy_filters:
  - comment: "ip4 check"
    content: "^ip4.me$"
  - comment: "ip6 check"
    content: "^ip6.me$"
openwrt_tinyproxy_allow:
  - "10.10.130.0/24"
  - "127.0.0.1"
```

In this example only the net 10.10.130.0/24 is allowed to access the proxy. It acts as a whitelist proxy, allowing only ip4.me and ip6.me websites.

See [OpenWrt Tinyproxy docs](https://openwrt.org/docs/guide-user/services/proxy/tinyproxy) for a more detailed list of available options. Ansible variables are all lowercase, e.g.

OpenWrt UCI name: **StatFile**
Ansible name: **openwrt_tinyproxy_statfile**
