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
    keylength: 4096
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
    use_staging: 0
    update_uhttpd: 1
```

If you use `validation_method: 'webroot'` you also need to specify a `path` attribute within the `openwrt_acme_cert` dict item. In the above example below `maincert`.
