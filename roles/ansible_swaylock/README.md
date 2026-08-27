# imp1sh.ansible_managemynetwork.ansible_swaylock

Manages [swaylock](https://github.com/swaywm/swaylock) screen locker configuration per-user on Fedora and Debian. Deploys `~/.config/swaylock/config` with appearance and behaviour settings. Complements `ansible_sway` (which installs the binary and triggers swaylock via swayidle).

Supports **per-user configs** — different wallpapers, colours, or behaviour for each user on the same host.

All option names match the swaylock man page exactly. Boolean flags are bare keywords in the config file (e.g. `show-failed-attempts`); value options use `long-option=value` (e.g. `ring-color=#ff00ff`).

## What it does

| Step | Action |
|------|--------|
| **1. Install** | Installs `swaylock` via `ansible_packages` |
| **2. Config dir** | Creates `~/.config/swaylock/` per target user |
| **3. Config file** | Renders `~/.config/swaylock/config` from template, merging per-user overrides |

## Variables

### Core

| Variable | Default | Description |
|----------|---------|-------------|
| `swaylock_users` | `null` | Target user(s): string, list, or null (= `ansible_user`) |
| `swaylock_config` | _(see below)_ | Base config dict — applies to all users |
| `swaylock_configs` | `{}` | Per-user overrides, keyed by username |

### swaylock_config (base)

Dict with the following keys. Override individual keys in `group_vars`/`host_vars` via the `combine` filter.

#### Value options

| Key | Default | Man page option | Description |
|-----|---------|-----------------|-------------|
| `image` | `~/.config/sway/wallpaper/Retro-Programmer.jpeg` | `image` | Background image path |
| `scaling` | `fill` | `scaling` | stretch, fill, fit, center, tile, solid_color |
| `color_inside` | `#1c1c1c` | `inside-color` | Inside of indicator |
| `color_ring` | `#ffaa00` | `ring-color` | Ring of indicator (typing/idle) |
| `color_key_hint` | `#ffb74d` | `key-hl-color` | Key press highlight segments |
| `color_bs_hover` | `#ffaa00` | `bs-hl-color` | Backspace highlight segments |
| `color_text` | `#ffffff` | `text-color` | Text colour |
| `color_line` | `#1c1c1c` | `line-color` | Line between inside and ring |
| `color_separator` | `#1c1c1c` | `separator-color` | Lines separating highlight segments |
| `indicator_radius` | `50` | `indicator-radius` | Indicator radius |
| `indicator_thickness` | `10` | `indicator-thickness` | Indicator thickness |

#### Boolean flags (emit as bare keyword when true)

| Key | Default | Man page option | Description |
|-----|---------|-----------------|-------------|
| `ignore_empty` | `true` | `ignore-empty-password` | Don't validate empty passwords |
| `indicator_idle_visible` | `false` | `indicator-idle-visible` | Show indicator when idle |
| `no_unlock_indicator` | `false` | `no-unlock-indicator` | Disable the unlock indicator |

#### Optional value options (only render when defined)

Any of these can be added to `swaylock_config` or per-user `swaylock_configs`:

| Key | Man page option | Description |
|-----|-----------------|-------------|
| `color` | `color` | Solid background colour |
| `font` | `font` | Text font |
| `font_size` | `font-size` | Fixed font size |
| `indicator_x_position` | `indicator-x-position` | Horizontal indicator position |
| `indicator_y_position` | `indicator-y-position` | Vertical indicator position |
| `color_layout_bg` | `layout-bg-color` | Layout box background |
| `color_layout_border` | `layout-border-color` | Layout box border |
| `color_layout_text` | `layout-text-color` | Layout text colour |
| `inside_ver_color` | `inside-ver-color` | Inside colour when verifying |
| `inside_wrong_color` | `inside-wrong-color` | Inside colour when invalid |
| `inside_clear_color` | `inside-clear-color` | Inside colour when cleared |
| `ring_ver_color` | `ring-ver-color` | Ring colour when verifying |
| `ring_wrong_color` | `ring-wrong-color` | Ring colour when invalid |
| `ring_clear_color` | `ring-clear-color` | Ring colour when cleared |
| `text_ver_color` | `text-ver-color` | Text colour when verifying |
| `text_wrong_color` | `text-wrong-color` | Text colour when invalid |
| `text_clear_color` | `text-clear-color` | Text colour when cleared |
| `line_ver_color` | `line-ver-color` | Line colour when verifying |
| `line_wrong_color` | `line-wrong-color` | Line colour when invalid |
| `line_clear_color` | `line-clear-color` | Line colour when cleared |

#### Optional boolean flags (only render when defined and true)

| Key | Man page option | Description |
|-----|-----------------|-------------|
| `show_keyboard_layout` | `show-keyboard-layout` | Display current xkb layout while typing |
| `show_failed_attempts` | `show-failed-attempts` | Show count of failed auth attempts |
| `hide_keyboard_layout` | `hide-keyboard-layout` | Force-hide xkb layout |
| `disable_caps_lock_text` | `disable-caps-lock-text` | Disable Caps Lock text |
| `indicator_caps_lock` | `indicator-caps-lock` | Show Caps Lock state on indicator |
| `line_uses_inside` | `line-uses-inside` | Use inside colour for the line |
| `line_uses_ring` | `line-uses-ring` | Use ring colour for the line |

### swaylock_configs (per-user overrides)

Dict keyed by username. Each entry is shallow-merged over `swaylock_config`, so you only specify the keys that differ. Users not listed here get the base config verbatim.

```yaml
swaylock_configs:
  jochen:
    show_keyboard_layout: true
    show_failed_attempts: true
    color_ring: "#e94560"
    color_layout_bg: "#16213e"
    color_layout_border: "#e94560"
    color_layout_text: "#eeeaea"
  alice:
    image: "~/.local/share/wallpapers/blue.jpg"
    color_ring: "#00aaff"
```

## Usage

In `group_vars/os_desktop_fedora.yml`:

```yaml
swaylock_users:
  - jochen

swaylock_configs:
  jochen:
    show_keyboard_layout: true
    show_failed_attempts: true
```

Playbook:

```yaml
- hosts: os_desktop_fedora
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_swaylock
```

## Relationship to ansible_sway

`ansible_sway` installs the `swaylock` binary and invokes it via `swayidle` in the sway config template (`swaylock --image <path> --scaling fill`). This role owns the **standalone config file** that swaylock reads for all its appearance and behaviour settings. The `swaylock_config.image` key should match the `sway_image_lock` var from `ansible_sway` so the lock screen wallpaper is consistent.
