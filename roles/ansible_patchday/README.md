# imp1sh.ansible_managemynetwork.ansible_patchday

This role applies system updates (patches) on Debian and Red Hat-family hosts. It checks for available updates, applies them, cleans up, and reboots if required.

## Features

- Checks for available updates before applying (skips hosts that are up to date)
- Applies all available updates via `dnf` (Red Hat) or `apt` (Debian)
- Autoremoves obsolete packages
- Detects if a reboot is required (via reboot-required flag or kernel version mismatch)
- **Grace period with notifications before reboot** — wall messages to all TTYs and sway/Wayland notifications via `notify-send`
- Post-reboot verification (checks kernel version and uptime)

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `patchday_skip_reboot` | `false` | Skip reboot entirely even if one is required |
| `patchday_reboot_timeout` | `600` | Seconds to wait for the host to come back after reboot |
| `patchday_post_reboot_delay` | `30` | Seconds to wait after reboot before verifying |
| `patchday_reboot_grace_period` | `180` | Grace period in seconds before rebooting (0 = immediate) |
| `patchday_reboot_notify` | `true` | Send wall + notify-send notifications during grace period |

## Grace period and notifications

When a reboot is required and `patchday_reboot_notify` is enabled, the role:

1. Schedules `shutdown -r +N` which broadcasts wall messages to all logged-in TTYs
2. Sends a critical `notify-send` notification to all Wayland sessions (visible in dunst/mako/sway)
3. Waits the configured grace period (default 180 seconds = 3 minutes)
4. Cancels the scheduled shutdown
5. Performs the actual reboot via `ansible.builtin.reboot`

This gives users time to save their work before the system goes down.

```yaml
# 5-minute grace period
patchday_reboot_grace_period: 300

# Immediate reboot, no grace period
patchday_reboot_grace_period: 0

# Disable notifications (silent reboot)
patchday_reboot_notify: false
```

## Usage

```yaml
- hosts: os_server_debian,os_desktop_fedora
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_patchday
```
