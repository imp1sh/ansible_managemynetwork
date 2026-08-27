# imp1sh.ansible_managemynetwork.ansible_thunar

Manages [Thunar](https://docs.xfce.org/xfce/thunar/start) file manager configuration per-user on Fedora and Debian. Deploys three config files:

| File | Purpose | Source |
|------|---------|--------|
| `~/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml` | View preferences, sort order, zoom, misc behavioural settings | Templated from `thunar_settings` dict |
| `~/.config/Thunar/accels.scm` | Keyboard accelerator map | Static file (`files/accels.scm`) |
| `~/.config/Thunar/uca.xml` | Custom actions (right-click menu entries) | Templated from `thunar_custom_actions` list |

Settings are driven entirely by variables — set them in `group_vars`/`host_vars` to steer per-group or per-host.

## Variables

### Core

| Variable | Default | Description |
|----------|---------|-------------|
| `thunar_users` | `null` | Target user(s): string, list, or null (= `ansible_user`) |
| `thunar_settings` | _(see below)_ | Dict of Xfconf properties → `{type, value}` |
| `thunar_custom_actions` | _(see below)_ | List of custom action dicts |
| `thunar_accels_src` | `accels.scm` | Filename in `files/` to deploy as `accels.scm` |

### thunar_settings

Each key is an Xfconf property name. Value is a dict with `type` (`string`/`int`/`bool`) and `value`.

Default (captured from a live Fedora desktop):

```yaml
thunar_settings:
  last-view:
    type: string
    value: "ThunarDetailsView"
  default-view:
    type: string
    value: "ThunarDetailsView"
  last-sort-column:
    type: string
    value: "THUNAR_COLUMN_NAME"
  last-sort-order:
    type: string
    value: "GTK_SORT_ASCENDING"
  misc-single-click:
    type: bool
    value: false
  misc-date-style:
    type: string
    value: "THUNAR_DATE_STYLE_YYYYMMDD"
  misc-full-path-in-tab-title:
    type: bool
    value: true
  misc-show-delete-action:
    type: bool
    value: true
  # ... (see defaults/main.yml for the full set)
```

Override individual keys without rewriting the whole dict by using `combine`:

```yaml
thunar_settings: "{{ thunar_settings | combine({'misc-single-click': {'type': 'bool', 'value': true}}) }}"
```

### thunar_custom_actions

List of custom action dicts. Recognised fields: `icon`, `name`, `submenu`, `unique_id`, `command`, `description`, `range`, `patterns`, `startup_notify`, and boolean appearance flags (`directories`, `text_files`, `image_files`, `other_files`, `audio_files`, `video_files`).

Default:

```yaml
thunar_custom_actions:
  - icon: "utilities-terminal"
    name: "Terminal hier öffnen"
    unique_id: "1744900021289548-1"
    command: "exo-open --working-directory %f --launch TerminalEmulator"
    description: "Öffnet ein Terminal im aktuellen Verzeichnis"
    patterns: "*"
    startup_notify: true
    directories: true
```

## Per-user configs

Different users can get different Thunar settings and/or custom actions. Two override dicts, both keyed by username:

### thunar_configs (settings overrides)

Shallow-merged over `thunar_settings` — individual Xfconf properties are replaced, the rest inherited.

```yaml
thunar_configs:
  jochen:
    misc-single-click:
      type: bool
      value: false
  alice:
    misc-single-click:
      type: bool
      value: true
    default-view:
      type: string
      value: "ThunarIconView"
```

### thunar_custom_action_configs (custom actions overrides)

**Replaces** the base `thunar_custom_actions` list entirely for that user. Users not listed here get the base list verbatim.

```yaml
thunar_custom_action_configs:
  alice:
    - icon: "utilities-terminal"
      name: "Open Terminal Here"
      unique_id: "1744900021289548-2"
      command: "exo-open --working-directory %f --launch TerminalEmulator"
      description: "Open a terminal in the current directory"
      patterns: "*"
      startup_notify: true
      directories: true
```

## Usage

In `group_vars/os_desktop_fedora.yml`:

```yaml
thunar_users:
  - jochen
```

Playbook:

```yaml
- hosts: os_desktop_fedora
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_thunar
```

## Packages

Installs `thunar` plus volman, archive, and media-tags plugins (package names vary by distro; see `vars/Fedora.yml` and `vars/Debian.yml`).
