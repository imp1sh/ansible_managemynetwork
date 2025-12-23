Role Name
=========

ansible_dunst - Ansible role for managing the dunst desktop notification daemon

This role installs and configures the dunst notification daemon on Linux systems. It supports both Fedora and Debian-based distributions, with full support for Wayland compositors.

Requirements
------------

- Ansible 2.1 or higher
- Target systems must be Fedora or Debian-based Linux distributions
- The role depends on `imp1sh.ansible_managemynetwork.ansible_packages` for package management

Role Variables
--------------

### OS-Specific Variables (defined in vars/)

These variables are automatically set based on the target distribution:

- `dunst_packagename`: Package name for dunst (default: "dunst")
- `dunst_fileconfig`: Configuration filename (default: "dunstrc")
- `dunst_servicename`: Service name (default: "dunst")
- `dunst_filetemplate`: Template filename (default: "dunstrc.j2")
- `dunst_userconfig`: Whether to use user config (default: true)

**Which users get the configuration?**

- **Default behavior** (when `dunst_users` is not set): The configuration is created for the user that Ansible connects as (the `ansible_user` or `remote_user`).
- **Specify a user**: Set `dunst_users: "alice"` to configure for user "alice" regardless of who Ansible connects as.
- **Multiple users**: Set `dunst_users: ["alice", "bob"]` to configure for multiple users.
- **System-wide**: Set `dunst_userconfig: false` to use `/etc/dunst/dunstrc` (system-wide, readable by all users).

### Configuration Variables (defined in defaults/main.yml)

- `dunst_userconfig`: Whether to use user-specific configuration (default: true). When true, config is placed in `~/.config/dunst/dunstrc`. When false, uses system-wide `/etc/dunst/dunstrc`.

- `dunst_users`: Target user(s) for configuration (default: null, which means the user Ansible connects as).
  - If `null` or undefined: Configures for the user Ansible connects as (`ansible_user`)
  - If a string (e.g., `"alice"`): Configures for that single user
  - If a list (e.g., `["alice", "bob"]`): Configures for all users in the list

- `dunst_color_scheme`: Color scheme selection (default: "dark").
  - Options: `"dark"` (default), `"light"`, `"vibrant"`
  - Each scheme defines colors for frame, background, and foreground for all urgency levels
  - You can still override individual color variables if needed

All configuration variables are prefixed with `dunst_config_` and organized by section:

#### Global Settings

- `dunst_config_global_monitor`: Monitor number (default: 0)
- `dunst_config_global_follow`: Follow mode - "mouse", "keyboard", or "none" (default: "mouse")
- `dunst_config_global_geometry`: Window geometry (default: "300x5-30+30")
- `dunst_config_global_font`: Font specification (default: "Monospace 10")
- `dunst_config_global_format`: Notification format string (default: "<b>%s</b>\n%b")
- `dunst_config_global_alignment`: Text alignment - "left", "center", or "right" (default: "left")
- `dunst_config_global_transparency`: Background transparency 0-100 (default: 10)
- `dunst_config_global_frame_color`: Frame color (set by color scheme, can be overridden)
- `dunst_config_global_icon_position`: Icon position - "left", "right", or "off" (default: "left")
- `dunst_config_global_max_icon_size`: Maximum icon size in pixels (default: 64)
- `dunst_config_global_history_length`: Number of notifications to keep in history (default: 20)
- `dunst_config_global_sticky_history`: Keep notifications in history (default: true)
- `dunst_config_global_word_wrap`: Enable word wrapping (default: true)
- `dunst_config_global_stack_duplicates`: Stack duplicate notifications (default: true)
- `dunst_config_global_show_indicators`: Show notification indicators (default: true)
- `dunst_config_global_idle_threshold`: Idle threshold in seconds (default: 120)
- `dunst_config_global_show_age_threshold`: Show age threshold in seconds (default: 60)
- `dunst_config_global_markup`: Markup mode - "full", "strip", or "no" (default: "full")
- `dunst_config_global_verbosity`: Verbosity level - "crit", "warn", "mesg", or "info" (default: "mesg")

And many more. See `defaults/main.yml` for the complete list.

#### Urgency Settings

Configure appearance and behavior for different urgency levels (low, normal, critical):

- `dunst_config_urgency_{low|normal|critical}_background`: Background color
- `dunst_config_urgency_{low|normal|critical}_foreground`: Foreground color
- `dunst_config_urgency_{low|normal|critical}_timeout`: Timeout in seconds (0 = no timeout)
- `dunst_config_urgency_{low|normal|critical}_frame_color`: Frame color

#### Experimental Settings (Wayland Support)

- `dunst_config_experimental_per_monitor_dpi`: Enable per-monitor DPI (default: false)
- `dunst_config_experimental_wayland_no_ignore_compositor`: Don't ignore compositor (default: false)

Dependencies
------------

This role depends on:
- `imp1sh.ansible_managemynetwork.ansible_packages` - For package installation

Example Playbook
----------------

Basic usage:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_dunst
```

With custom configuration:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_dunst
      vars:
        dunst_config_global_font: "DejaVu Sans 11"
        dunst_config_global_geometry: "400x10-40+40"
        dunst_config_global_transparency: 20
        dunst_config_urgency_critical_timeout: 0
        dunst_config_urgency_critical_background: "#ff0000"
```

Configure for a specific user:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_dunst
      vars:
        dunst_users: "alice"
```

Configure for multiple users:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_dunst
      vars:
        dunst_users: ["alice", "bob", "charlie"]
```

Use system-wide configuration:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_dunst
      vars:
        dunst_userconfig: false
```

Select a color scheme:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_dunst
      vars:
        dunst_color_scheme: "light"  # Options: "dark" (default), "light", "vibrant"
```

Available color schemes:
- **dark** (default): Dark blue theme with white text, red for critical notifications
- **light**: Light gray theme with black text, suitable for light desktop environments
- **vibrant**: Modern dark theme with blue accents and pink for critical notifications

You can still override individual colors even when using a color scheme:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_dunst
      vars:
        dunst_color_scheme: "dark"
        dunst_config_urgency_critical_background: "#ff0000"  # Override just this color
```

License
-------

MIT-0

Author Information
------------------

This role is part of the ansible_managemynetwork collection.
