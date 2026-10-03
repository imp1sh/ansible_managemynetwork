# imp1sh.ansible_managemynetwork.ansible_blocky

Deploys and configures blocky DNS adblocker/proxy.

## Requirements

- Podman installed on the target host

## Variables

| Variable | Required | Description |
|----------|:--------:|-------------|
| `blocky_config` | yes | Dict of blocky configuration options |

## Example Playbook

```yaml
- hosts: dns
  roles:
    - imp1sh.ansible_managemynetwork.ansible_blocky
```
