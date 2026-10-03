# imp1sh.ansible_managemynetwork.ansible_actrunner

Renders act_runner config.yaml for a Gitea Actions runner podman container.

## Requirements

- Podman installed on the target host
- Gitea instance with Actions enabled

## Variables

| Variable | Required | Description |
|----------|:--------:|-------------|
| `actrunner_config` | yes | Dict of act_runner configuration options |

## Example Playbook

```yaml
- hosts: runners
  roles:
    - imp1sh.ansible_managemynetwork.ansible_actrunner
```
