# imp1sh.ansible_managemynetwork.ansible_gtk3

Manages GTK3 user configuration per-user on Fedora and Debian. Deploys two files into `~/.config/gtk-3.0/`:

| File | Purpose | Source |
|------|---------|--------|
| `settings.ini` | GtkSettings properties (theme, fonts, cursor, dark mode, font rendering) | Templated from `gtk3_settings` dict |
| `bookmarks` | Sidebar shortcuts in file dialogs and Thunar | Templated from `gtk3_bookmarks` list |

Non-opinionated: all defaults are empty. Populate via `group_vars`/`host_vars`. Supports per-user overrides.

## What it does

| Step | Action |
|------|--------|
| **1. Config dir** | Creates `~/.config/gtk-3.0/` per target user |
| **2. settings.ini** | Renders from `gtk3_settings` dict (skipped if empty) |
| **3. bookmarks** | Renders from `gtk3_bookmarks` list (skipped if empty) |

No packages are installed — GTK3 is pulled in as a dependency by the desktop environment or applications themselves.

## Variables

### Core

| Variable | Default | Description |
|----------|---------|-------------|
| `gtk3_users` | `null` | Target user(s): string, list, or null (= `ansible_user`) |
| `gtk3_settings` | `{}` | Base settings dict — applies to all users |
| `gtk3_bookmarks` | `[]` | Base bookmarks list — applies to all users |
| `gtk3_configs` | `{}` | Per-user overrides, keyed by username |

### gtk3_settings

Dict of GtkSettings property names → string values. Property names are verified via `GtkSettings.list_properties()` from the GTK3 GObject introspection. Boolean properties accept `"0"` or `"1"`.

Common properties:

| Property | Type | Description |
|----------|------|-------------|
| `gtk-theme-name` | string | Name of theme to load |
| `gtk-icon-theme-name` | string | Name of icon theme to use |
| `gtk-font-name` | string | Default font family and size |
| `gtk-cursor-theme-name` | string | Cursor theme name |
| `gtk-cursor-theme-size` | int | Cursor size (0 = default) |
| `gtk-application-prefer-dark-theme` | bool | Prefer dark theme variant |
| `gtk-toolbar-style` | enum | Toolbar style (GTK_TOOLBAR_BOTH_HORIZ, etc.) |
| `gtk-toolbar-icon-size` | enum | Toolbar icon size |
| `gtk-button-images` | bool | Show images on buttons |
| `gtk-menu-images` | bool | Show images in menus |
| `gtk-enable-animations` | bool | Enable toolkit-wide animations |
| `gtk-enable-event-sounds` | bool | Play event sounds |
| `gtk-enable-input-feedback-sounds` | bool | Play input feedback sounds |
| `gtk-xft-antialias` | int | Antialias Xft fonts (-1=default, 0=no, 1=yes) |
| `gtk-xft-hinting` | int | Hint Xft fonts (-1=default, 0=no, 1=yes) |
| `gtk-xft-hintstyle` | string | Hinting degree (hintnone, hintslight, hintmedium, hintfull) |
| `gtk-xft-rgba` | string | Subpixel antialiasing (none, rgb, bgr, vrgb, vbgr) |
| `gtk-xft-dpi` | int | Resolution in 1024*dots/inch (-1=default) |
| `gtk-overlay-scrolling` | bool | Use overlay scrollbars |
| `gtk-dialogs-use-header` | bool | Use header bars in builtin dialogs |
| `gtk-key-theme-name` | string | Key theme to load |
| `gtk-im-module` | string | Input method module |
| `gtk-recent-files-enabled` | bool | Remember recent files |
| `gtk-error-bell` | bool | Beep on keyboard nav errors |

See `GtkSettings` GObject properties for the complete list (70+ properties).

### gtk3_bookmarks

List of sidebar shortcut entries. Each entry can be:

- A **string** (just the URI): `"file:///home/user/Downloads"`
- A **dict** with `uri` and optional `label`: `{"uri": "file:///home/user/Downloads", "label": "Downloads"}`

Supported URI schemes: `file://`, `sftp://`, `smb://`, `dav://`, `recent://`, `trash://`, etc.

```yaml
gtk3_bookmarks:
  - uri: "file:///home/jochen/Downloads"
    label: "Downloads"
  - uri: "file:///home/jochen/Bilder"
  - "sftp://user@host/path Remote Share"
```

### gtk3_configs (per-user overrides)

Dict keyed by username. Each entry can contain:

- `settings` — shallow-merged over `gtk3_settings` (individual properties replaced)
- `bookmarks` — **replaces** the base `gtk3_bookmarks` list entirely

Users not listed here get the base config verbatim.

```yaml
gtk3_configs:
  jochen:
    settings:
      gtk-theme-name: "Adwaita"
      gtk-application-prefer-dark-theme: "1"
    bookmarks:
      - uri: "file:///home/jochen/Downloads"
        label: "Downloads"
      - uri: "file:///home/jochen/git"
  alice:
    settings:
      gtk-application-prefer-dark-theme: "0"
    bookmarks:
      - uri: "file:///home/alice/Documents"
```

## Usage

In `group_vars/os_desktop_fedora.yml`:

```yaml
gtk3_users:
  - jochen

gtk3_configs:
  jochen:
    settings:
      gtk-theme-name: "Adwaita"
      gtk-icon-theme-name: "Adwaita"
      gtk-font-name: "Noto Sans 10"
      gtk-application-prefer-dark-theme: "1"
      gtk-xft-antialias: "1"
      gtk-xft-hinting: "0"
      gtk-xft-hintstyle: "hintnone"
      gtk-xft-rgba: "rgb"
    bookmarks:
      - uri: "file:///home/jochen/Downloads"
        label: "Downloads"
      - uri: "file:///home/jochen/Bilder"
```

Playbook:

```yaml
- hosts: os_desktop_fedora
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_gtk3
```

## Scope

These files affect **every GTK3 application** on the host, not just Thunar. Bookmarks appear in all GTK file-open/save dialogs. Settings affect theme, fonts, and rendering for all GTK3 widgets. Under sway, this is the application-layer polish — the compositor layer is controlled by sway itself.
