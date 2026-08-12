# imp1sh.ansible_managemynetwork.ansible_openwrtuhttpd

OpenWrt uses the lightweight uhttpd webserver in order to make the LUCI WebGUI available. This role administers the configuration for that webservice.

## Requirements

- The `community.dns` Ansible collection must be installed when using the ACME certificate auto-discovery feature (used for extracting the registrable domain from `inventory_hostname`).

This is how a playbook can look like:

role_openwrtuhttpd.yml
```yaml
---
- hosts: platforms_openwrt
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_openwrtuhttpd
```

Even without a single variable set the role will deploy a default configuration equal to how the OpenWrt configuration look like on a fresh install. The only difference is that it will redirect to https as a default.

Boolean/integer values accept both quoted (`"1"`) and unquoted (`1`) forms; UCI stores everything as strings and the consuming init script compares textually, so the two are interchangeable. Quoting is recommended to avoid YAML silently coercing words like `yes`/`no`/`on`/`off`/`true`/`false`.

## Variables

### Server settings (`uhttpd` section)

Unless noted otherwise, every variable is optional.

#### Listeners and document root

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_uhttpd_main_listen_http` | list[string] | `["0.0.0.0:80", "[::]:80"]` | Address:port pairs to listen on for plain HTTP. |
| `openwrt_uhttpd_main_listen_https` | list[string] | `["0.0.0.0:443", "[::]:443"]` | Address:port pairs to listen on for HTTPS. Requires cert+key. |
| `openwrt_uhttpd_main_home` | string | `/www` | Document root directory. |
| `openwrt_uhttpd_main_enabled` | bool (`0`/`1`) | `1` | Enable/disable this uhttpd instance. |

#### TLS / certificates

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_uhttpd_main_cert` | filepath | `/etc/uhttpd.crt` | Path to the TLS certificate (DER or PEM). Intermediate certs may be concatenated (PEM only). |
| `openwrt_uhttpd_main_key` | filepath | `/etc/uhttpd.key` | Path to the TLS private key (DER or PEM). |
| `openwrt_uhttpd_main_redirect_https` | bool (`0`/`1`) | `1` | Redirect all HTTP requests to HTTPS. |

See *Certificates* below for auto-discovery behaviour.

#### Request limits and timeouts

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_uhttpd_main_max_requests` | uint | `3` | Maximum concurrent script/CGI/Lua requests. Excess requests queue. |
| `openwrt_uhttpd_main_max_connections` | uint | `100` | Maximum concurrent TCP connections. Excess connections queue. |
| `openwrt_uhttpd_main_script_timeout` | uint | `60` | Seconds to wait for CGI/Lua/ubus output before killing the process. |
| `openwrt_uhttpd_main_network_timeout` | uint | `30` | Seconds of network inactivity before shutting down a connection. |
| `openwrt_uhttpd_main_http_keepalive` | uint | `20` | HTTP keep-alive connection reuse count. Set `0` to disable. |
| `openwrt_uhttpd_main_tcp_keepalive` | uint | `1` | TCP keepalive interval. |

#### CGI, Lua and ucode

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_uhttpd_main_cgi_prefix` | string | `/cgi-bin` | URL prefix for CGI scripts. CGI disabled if unset. |
| `openwrt_uhttpd_main_lua_prefix` | list[string] | `["/cgi-bin/luci=/usr/lib/lua/luci/sgi/uhttpd.lua"]` | Virtual path = handler mappings for the embedded Lua interpreter. Each entry must be `prefix=handler`. |
| `openwrt_uhttpd_main_lua_handler` | string | – | Full path to Lua handler script (legacy single-prefix form). |
| `openwrt_uhttpd_main_ucode_prefix` | list[string] | – | Virtual path = handler mappings for the ucode interpreter. Each entry must be `prefix=handler`. |
| `openwrt_uhttpd_main_interpreter` | list[string] | – | CGI filetype handlers, e.g. `.php=/usr/bin/php-cgi`. Each entry must be `suffix=handler`. |

#### ubus / JSON-RPC

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_uhttpd_main_ubus_prefix` | string | `/ubus` | URL prefix for ubus via JSON-RPC. ubus disabled if unset. |
| `openwrt_uhttpd_main_ubus_socket` | string | – | Override path for the ubus socket. |
| `openwrt_uhttpd_main_no_ubusauth` | bool (`0`/`1`) | `0` | Skip JSON-RPC authorization via ubus session API. |
| `openwrt_uhttpd_main_ubus_cors` | bool (`0`/`1`) | `0` | Enable CORS HTTP headers on the JSON-RPC API. |

#### Index pages, aliases and error handling

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_uhttpd_main_index_page` | list[string] | – | Index page filenames, e.g. `["index.html", "index.php"]`. |
| `openwrt_uhttpd_main_alias` | list[string] | – | URL aliases, e.g. `/old/path=/new/path`. |
| `openwrt_uhttpd_main_error_page` | string | – | Virtual URL or CGI script for 404 handling. Must begin with `/`. |
| `openwrt_uhttpd_main_json_script` | list[string] | – | JSON script hook files. |

#### Authentication and security

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_uhttpd_main_realm` | string | system hostname | Basic-auth realm. |
| `openwrt_uhttpd_main_config` | filepath | – | Busybox httpd-format config file (for Basic Auth areas). |
| `openwrt_uhttpd_main_httpauth` | list[string] | – | Basic-auth entries as `prefix:username:password` strings. |
| `openwrt_uhttpd_main_rfc1918_filter` | bool (`0`/`1`) | `1` | Reject RFC1918-sourced requests to public IPs (DNS rebinding defence). |
| `openwrt_uhttpd_main_no_symlinks` | bool (`0`/`1`) | `0` | Do not follow symlinks outside the document root. |
| `openwrt_uhttpd_main_no_dirlists` | bool (`0`/`1`) | `0` | Disable directory listings. |

### Certificate defaults (`cert` section)

These control the self-signed certificate generated by uhttpd on first start (via `px5g` or `openssl`). Ignored when you supply your own cert/key.

| Variable | Type | Valid values | Default | Description |
|---|---|---|---|---|
| `openwrt_uhttpd_cert_days` | uint | ≥0 | `730` | Certificate validity in days. |
| `openwrt_uhttpd_cert_key_type` | string | `rsa`, `ec` | `ec` | Key type. |
| `openwrt_uhttpd_cert_bits` | uint | ≥1024 | `2048` | RSA key length in bits. Ignored when `key_type=ec`. |
| `openwrt_uhttpd_cert_ec_curve` | string | e.g. `P-256` | `P-256` | EC curve name. Used only when `key_type=ec`. |
| `openwrt_uhttpd_cert_country` | string | – | `ZZ` | ISO country code. |
| `openwrt_uhttpd_cert_state` | string | – | `Somewhere` | State or province. |
| `openwrt_uhttpd_cert_location` | string | – | `Unknown` | Locality. |
| `openwrt_uhttpd_cert_organization` | string | – | – | Organization. Defaults to `OpenWrt` + random ID when unset. |
| `openwrt_uhttpd_cert_commonname` | string | – | `OpenWrt` | Certificate CommonName (CN). |

### Deployment internals

| Variable | Type | Default | Description |
|---|---|---|---|
| `openwrt_uhttpd_deployroot` | string | `/` | Root prefix for all deploy paths. |
| `openwrt_uhttpd_deploypath` | string | `<deployroot>etc/config` | Destination directory for the uhttpd UCI file. |
| `openwrt_uhttpd_deployfile` | string | `uhttpd` | Filename of the uhttpd UCI config. |
| `openwrt_uhttpd_acme_searchpaths` | list[string] | (see defaults) | Directories searched for ACME/Let's Encrypt certificates. |
| `openwrt_uhttpd_runimagebuilder` | bool | `false` | Skip cert-handling tasks and service-restart handlers (Image Builder/chroot mode). |
| `openwrt_imagebuilder_buildhost` | string | – | External host to delegate rendering/deploy to when building images elsewhere. Provided by the caller play, not this role. |

## Certificates

The role searches for certificates in this order:

1. **Explicitly provided** — if you set `openwrt_uhttpd_main_cert` and `openwrt_uhttpd_main_key` to custom paths, the role verifies they exist and uses them.
2. **From ansible_cacert role** — searches `/etc/ssl/certs/` for `*_{{ inventory_hostname }}_certificate.pem` and `/etc/ssl/private/` for `*_{{ inventory_hostname }}_privatekey.pem` (matching the naming convention of the `ansible_cacert` role).
3. **From ACME/Let's Encrypt** — searches `/etc/acme/` for hostname-based and domain-based cert directories, looking for `fullchain.cer` and matching `.key` files. Prioritizes hostname-specific keys over domain wildcard keys.
4. **Default fallback** — uses `/etc/uhttpd.crt` and `/etc/uhttpd.key` (self-generated by uhttpd on first start).

You can override the ACME search paths with `openwrt_uhttpd_acme_searchpaths`.
