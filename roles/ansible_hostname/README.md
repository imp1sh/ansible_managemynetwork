# imp1sh.ansible_managemynetwork.ansible_dehydrated

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_hostname)

This role sets the hostname of a host.
It currently supports these Operating Systems:
- Debian
- Ubuntu (best effort)
- FreeBSD (best effort)
- ~~Alpine~~ (probably works but no longer supported)
- ~~Arch~~ (probably works but no longer supported)
- ~~Manjaro~~ (probably works but no longer supported)

This role will set the hostname to the value of the variable `system_hostname` or if not defined to `inventory_hostname`.
