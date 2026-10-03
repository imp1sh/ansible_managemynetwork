# imp1sh.ansible_managemynetwork.ansible_smartd

Installs and configures smartd for automatic SMART disk health monitoring with email alerts.

## Requirements

- smartmontools package available on the target host

## Variables

| Variable | Required | Description |
|----------|:--------:|-------------|
| `smartd_email` | no | Email address for SMART alerts (default: root) |

## Example Playbook

```yaml
- hosts: servers
  roles:
    - imp1sh.ansible_managemynetwork.ansible_smartd
```
