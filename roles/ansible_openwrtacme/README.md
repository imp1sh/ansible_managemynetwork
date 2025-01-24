# imp1sh.ansible_managemynetwork.ansible_openwrtacme
With ansible_openwrt you can manage Letsencrypt certificates for your OpenWrt devices. There are three different modes:

1) DNS
Uses the DNS-01 challenge
2) Webroot
Uses the HTTP-01 challenge. It facilitates a third party webserver.
3) Standalone
Same as 2) but uses the builtin uhttpd webserver.

Example configuration for DNS-01 challenge:
```yaml
openwrt_acme_account_email: "you@email.com"
openwrt_acme_cert:
  maincert:
    key_type: ec256
    domains:
      - "{{ inventory_hostname }}"
    validation_method: "dns"
    dns: "dns_pdns"
    credentials:
      - "PDNS_ServerId=localhost"
      - "PDNS_Ttl=60"
      - "PDNS_Url=\"https://yourapi_endpoint.com\""
      - "PDNS_Token=\"yoursupersecurepassword\""
    enabled: 1
    staging: 0
```

## Variables

* `openwrt_acme_hooks` - (Optional, see [Default](./defaults/main.yml)) list of services to reload after certificate renewal.\
  [Openwrt Hooks](https://openwrt.org/docs/guide-user/services/tls/acmesh#hooks) \
  Each item is a dictionary with the following keys:
  * `name` - name of the service to restart/reload
  * `action` (Optional, default: reload) - action to perform

* `openwrt_acme_root_cas` - (Optional) list of root CA certificates to trust. \
  [Openwrt trusting Root CA](https://openwrt.org/docs/guide-user/services/tls/pki) \
  Each item is a dictionary with the following keys:
  * `name` - name of the root CA certificate
  * `context` - context of the root CA certificate

* `openwrt_acme_webroot_config` - (Default: true) - Add links for .well-known/acme-challenge \
  [Openwrt Webroot](https://openwrt.org/docs/guide-user/services/tls/acmesh#webroot)

### [UCI Config Options](https://openwrt.org/docs/guide-user/services/tls/acmesh#uci_config_options)
* `openwrt_acme_account_email` (Required) `account_email`
* `openwrt_acme_debug` (Optional) `debug`
* `openwrt_acme_cert` (Required) List of certificates to manage. Config of each certificate is same as OpenWrt documentation. 