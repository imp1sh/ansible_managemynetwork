# imp1sh.ansible_managemynetwork.ansible_sway

Ansible role for managing the Sway window manager

This role installs and configures the Sway window manager on Linux systems. 

## Requirements

- Ansible 2.9 or higher
- Fedora 43 or 44
- Debian 13
- The role depends on `imp1sh.ansible_managemynetwork.ansible_packages` for package management

## Role Variables

### OS-Specific Variables (defined in vars/)

These variables are automatically set based on the target distribution:

- `sway_packages`: List of packages to install
- `sway_fileconfig`: Configuration filename
- `sway_filetemplate`: Template filename
- `sway_userconfig`: Whether to deploy user specific config (default: true)

**Which users get the configuration?**

- **Default behavior** (when `sway_users` is not set): The configuration is created for the user that Ansible connects as (the `ansible_user` or `remote_user`).
- **Specify a user**: Set `sway_users: "alice"` to configure for user "alice" regardless of who Ansible connects as.
- **Multiple users**: Set `sway_users: ["alice", "bob"]` to configure for multiple users.
- **System-wide**: Set `sway_userconfig: false` to use `/etc/sway/config` (system-wide, readable by all users).

### Configuration Variables (defined in defaults/main.yml)

- `sway_userconfig`: Whether to use user-specific configuration (default: true). When true, config is placed in `~/.config/sway/config`. When false, uses system-wide `/etc/sway/config`.

- `sway_users`: Target user(s) for configuration (default: null, which means the user Ansible connects as).
  - If `null` or undefined: Configures for the user Ansible connects as (`ansible_user`)
  - If a string (e.g., `"alice"`): Configures for that single user
  - If a list (e.g., `["alice", "bob"]`): Configures for all users in the list

#### Basic Settings

- `sway_key_mod`: Modifier key (default: "Mod4" - Super/Windows key)
- `sway_terminal`: Terminal emulator command (default: "alacritty")
- `sway_menu`: Application launcher/menu command (default: "$rofi_cmd -show combi -combi-modes drun#run -modes combi")
- `sway_font`: Font specification (default: "pango:Monospace 10")

#### Color Configuration

- `sway_colors`: Dictionary of color settings for different elements.
  - `background`: Background color (default: "#1c1c1c")
  - `statusline`: Status line color (default: "#ffffff")
  - `focused`: Focused window color (default: "#ffaa00")
  - `border`: Border color (default: "#ffaa00")
  - `child_border`: Child border color (default: "#ffaa00")
  - `indicator`: Indicator color (default: "#1c1c1c")
  - `separator`: Separator color (default: "#1c1c1c")
  - `workspace`: Workspace color (default: "#ffaa00")
  - `inactive`: Inactive window color (default: "#2d2d2d")
  - `urgent`: Urgent window color (default: "#e63946")
  - `binding_mode`: Binding mode color (default: "#e63946")
  - `binding_mode_statusline`: Binding mode status line color (default: "#ffffff")
  - `binding_mode_separator`: Binding mode separator color (default: "#83343b")

#### Gaps Configuration

- `sway_gaps_inner`: Inner gaps in pixels (default: 0)
- `sway_gaps_outer`: Outer gaps in pixels (default: 0)

#### Keybindings Configuration

- `sway_keybindings`: List of custom keybindings.
  - `keys`: Key combination (e.g., "$mod+Return")
  - `command`: Command to execute

#### Window Attributes Configuration

- `sway_window_attributes`: Dictionary of window attributes and rules.
  - Keys are window names/markers
  - Values are lists of rules with:
    - `criteria`: Window criteria (e.g., "class:Firefox")
    - `workspace`: Target workspace number
    - `floating`: Whether to make window floating (true/false)

#### Exec Commands Configuration

- `sway_exec_commands`: List of commands to execute on startup.
  - `command`: Command to execute

#### Focus Configuration

- `sway_focus_wrapping`: Whether to wrap focus when reaching edges (default: null)
- `sway_focus_on_window_activation`: How to handle focus on window activation (default: null)
  - "smart", "urgent", or "none"
- `sway_mouse_warping`: How to handle mouse movement (default: null)
  - "output", "container", or "none"

#### Layout Configuration

- `sway_workspace_layout`: Default workspace layout (default: null)
  - "stacking", "tabbed", or "split"
- `sway_workspace_auto_back_and_forth`: Whether to auto-switch between workspaces (default: null)
- `sway_default_orientation`: Default orientation (default: null)
  - "horizontal" or "vertical"

#### Floating Configuration

- `sway_floating_modifier`: Modifier key for floating toggle (default: "$mod")
- `sway_floating_minimum_size`: Minimum size for floating windows (default: "75 x 50")
- `sway_floating_maximum_size`: Maximum size for floating windows (default: "-1 x -1")

#### Sway Configuration

- `sway_xwayland_disable`: Disable Xwayland (default: null)
- `sway_force_xwayland`: Force Xwayland (default: null)
- `sway_title_format`: Title format for windows (default: null)
- `sway_includes`: List of additional config files to include (default: [])

#### Output Configuration

Configure display outputs using the `sway_outputs` list:

```yaml
sway_outputs:
  - name: "*"
    background_image: "/usr/share/backgrounds/sway/sway_wallpaper.png"
    background_mode: "fill" # [ fill(default) | stretch | fit | center | tile ]
    background_color: "#000000" # alternatively you can specify a color. Image has precedence
    mode: "1920x1080"
    position: "0 0"
    scale: null
    transform: null
    adaptive_sync: null
    subpixel: null
    render_bit_depth: null
```

#### Input Configuration

Configure keyboard and mouse input using the `sway_inputs` list:

```yaml
sway_inputs:
  - identifier: "*"
    xkb_layout: "us"
    xkb_variant: null
    xkb_options: null
    xkb_numlock: null
    xkb_capslock: null
    repeat_delay: null
    repeat_rate: null
    natural_scroll: null
    scroll_method: null
    scroll_button: null
    left_handed: null
    accel_profile: null
    pointer_accel: null
    tap: null
    tap_button_map: null
    drag: null
    drag_lock: null
```

#### Window Configuration

- `sway_window_border`: Border width in pixels (default: 2)
- `sway_window_titlebar`: Enable titlebar (default: true)
- `sway_window_floating_border`: Floating window border width (default: 2)
- `sway_window_floating_titlebar`: Enable floating titlebar (default: true)
- `sway_window_hide_edge_borders`: Hide edge borders (default: null)
- `sway_window_hide_edge_borders_smart`: Smart edge border hiding (default: null)
- `sway_window_hide_edge_borders_when_only`: Hide edge borders when only window (default: null)

#### Gaps

- `sway_gaps_inner`: Inner gap size (default: 0)
- `sway_gaps_outer`: Outer gap size (default: 0)
- `sway_gaps_smart_borders`: Enable smart borders (default: null)
- `sway_gaps_smart_gaps`: Enable smart gaps (default: null)

#### Colors

Colors are configured as a nested dictionary under `sway_colors`:

- `sway_colors.background`: Background color
- `sway_colors.statusline`: Statusline color
- `sway_colors.focused.*`: Colors for focused windows (border, background, text, indicator, child_border, separator, statusline)
- `sway_colors.inactive.*`: Colors for inactive windows
- `sway_colors.urgent.*`: Colors for urgent windows
- `sway_colors.binding_mode.*`: Colors for binding mode

See `defaults/main.yml` for the complete structure.

#### Workspaces

Configure workspaces using the `sway_workspaces` list:

```yaml
sway_workspaces:
  - number: 1
    output: null
  - number: 2
    output: null
  - number: "3:mail"
    output: null
```

If not specified, default workspaces 1-10 are created.

#### Keybindings

Configure custom keybindings using the `sway_keybindings` list:

```yaml
sway_keybindings:
  - keys: "$mod+Return"
    command: "exec $term"
  - keys: "$mod+Shift+q"
    command: "kill"
  - keys: "$mod+d"
    command: "exec $menu"
```

If not specified, sensible default keybindings are used.

#### Mode Keybindings

Configure custom modes using the `sway_modes` list:

```yaml
sway_modes:
  - name: "resize"
    keybindings:
      - keys: "Left"
        command: "resize shrink width 10 px or 10 ppt"
      - keys: "Right"
        command: "resize grow width 10 px or 10 ppt"
```

If not specified, a default resize mode is created.

#### Bar Configuration

- `sway_bar_enabled`: Enable status bar (default: true)
- `sway_bar_id`: Bar identifier (default: "bar0")
- `sway_bar_mode`: Bar mode - "dock", "hide", or "invisible" (default: null)
- `sway_bar_hidden_state`: Hidden state - "hide" or "show" (default: null)
- `sway_bar_modifier`: Modifier key for bar (default: null)
- `sway_bar_position`: Bar position - "top" or "bottom" (default: "bottom")
- `sway_bar_status_command`: Status command (default: null)
- `sway_bar_font`: Bar font (default: null, uses `sway_font`)
- `sway_bar_wrap_scroll`: Wrap scroll (default: null)
- `sway_bar_workspace_buttons`: Show workspace buttons (default: null)
- `sway_bar_strip_workspace_numbers`: Strip workspace numbers (default: null)
- `sway_bar_binding_mode_indicator`: Show binding mode indicator (default: null)
- `sway_bar_separator_symbol`: Separator symbol (default: null)
- `sway_bar_tray_output`: Tray output (default: null)
- `sway_bar_tray_padding`: Tray padding (default: null)
- `sway_bar_colors`: Custom bar colors dictionary (default: null)
- `sway_bar_swaybar_command`: Swaybar command (default: null)

#### Window Assignments, Floating, Marking

Add markings, floating decision and workspace assignment in one big dictionary var.
Each rule requires `criteria`. Commands are chained with `,` (retains criteria in
`for_window`). Use the `raw` attribute to inject `;`-separated commands that reset
criteria (see sway(5) COMMAND CONVENTIONS).

Chained commands (applied via `for_window [criteria]`):

| Attribute | Type | Effect |
|-----------|------|--------|
| `floating` | bool \| string | `true`→enable, `false`→disable, `"toggle"` |
| `border` | string \| int | `none`, `normal`, `csd`, `toggle`, or int (→ `pixel <n>`) |
| `layout` | string | `default`, `splith`, `splitv`, `stacking`, `tabbed`, `toggle` |
| `opacity` | float \| string | e.g. `0.9`, or `"plus 0.1"`, `"minus 0.1"` |
| `fullscreen` | bool \| string | `true`→enable, `false`→disable, `"toggle"`, `"enable global"` |
| `sticky` | bool \| string | `true`→enable, `false`→disable, `"toggle"` |
| `inhibit_idle` | bool \| string | `true`→`open`, `false`→`none`, or `"focus"`,`"fullscreen"`,`"open"`,`"visible"`,`"none"` |
| `shortcuts_inhibitor` | bool | `true`→enable, `false`→disable |
| `max_render_time` | int \| string | milliseconds or `"off"` |
| `split` | string | `v`/`vertical`, `h`/`horizontal`, `t`/`toggle`, `none` |
| `urgent` | bool \| string | `true`→enable, `false`→disable, or `"allow"`,`"deny"` |
| `kill` | bool | kills the matching window |
| `title_format` | string | e.g. `"%title"` |
| `resize` | dict \| string | see below |
| `move` | dict \| string | see below |
| `raw` | string | injected as-is (use `;` to reset criteria) |

Standalone commands (emitted on separate lines with their own criteria):

| Attribute | Type | Effect |
|-----------|------|--------|
| `workspace` | int \| string | `assign [criteria] workspace number N` or `assign [criteria] workspace <name>` |
| `output` | string | `assign [criteria] output <name>` |
| `no_focus` | bool | `no_focus [criteria]` |

`resize` as dict:

```yaml
resize: {width: 800, height: 600}    # resize set width 800 px height 600 px
resize: {width: 800}                  # resize set width 800 px
resize: {action: "shrink", axis: "width", amount: 10}  # resize shrink width 10 px
resize: {action: "grow", axis: "height", amount: 5, unit: "ppt"}
```

`resize` as string: passed through after `resize `.

`move` as dict:

```yaml
move: {direction: "left", px: 10}     # move left 10 px
move: {position: "100 200"}          # move position 100 200
move: {position: [100, 200]}         # move position 100 200
move: {position: "100 200", absolute: true}  # move absolute position 100 200
move: {center: true}                 # move position center
move: {center: true, absolute: true} # move absolute position center
move: {cursor: true}                 # move position cursor
move: {to_workspace: 3}              # move container to workspace number 3
move: {to_workspace: "3:mail"}       # move container to workspace 3:mail
move: {to_workspace: "next"}        # move container to workspace next
move: {to_output: "HDMI-1"}         # move container to output HDMI-1
move: {to_scratchpad: true}          # move container to scratchpad
move: {to_mark: "somemark"}         # move container to mark somemark
```

`move` as string: passed through after `move `.

```
sway_window_attributes:
  Browser:
    - criteria: 'app_id="org.mozilla.firefox"'
      workspace: 2
    - criteria: 'app_id="google-chrome"'
      workspace: 3
    - criteria: 'app_id="librewolf"'
      workspace: 1
  Calendar:
    - criteria: 'app_id="org.gnome.Calendar"'
  Cloudsync:
    - criteria: 'app_id="com.seafile.seafile-applet"'
      workspace: 6
  Conference:
    - criteria: 'class="zoom"'
      workspace: 4
  Editor:
    - criteria: 'app_id="gedit"'
      floating: true
  Filebrowser:
    - criteria: 'app_id="Thunar"'
      floating: true
  IM:
    - criteria: 'app_id="org.signal.Signal"'
      workspace: 2
  Mail:
    - criteria: 'app_id="org.gnome.Evolution"'
      workspace: 1
    - criteria: 'app_id="net.thunderbird.Thunderbird"'
      workspace: 1
  Music:
    - criteria: 'class="Spotify"'
      workspace: 5
  Networkconfig:
    - criteria: 'app_id="nm-connection-editor"'
      floating: true
  Packagemanager:
    - criteria: 'title=".*dnfdragora.*"'
      floating: true
  Soundconfig:
    - criteria: 'app_id="org.pulseaudio.pavucontrol"'
      floating: true
  Terminalemulator:
    - criteria: 'app_id="Alacritty"'
```

#### Startup Applications

Execute commands on startup using the `sway_exec_commands` list:

```yaml
sway_exec_commands:
  - command: "swaybg -i /usr/share/backgrounds/sway/sway_wallpaper.png"
  - command: "waybar"
  - command: "mako"
```

#### Additional Settings

- `sway_focus_wrapping`: Focus wrapping (default: null)
- `sway_focus_on_window_activation`: Focus on window activation - "smart", "urgent", or "none" (default: null)
- `sway_mouse_warping`: Mouse warping - "output", "container", or "none" (default: null)
- `sway_popup_during_fullscreen`: Popup during fullscreen - "smart", "ignore", or "leave_fullscreen" (default: null)
- `sway_workspace_auto_back_and_forth`: Workspace auto back and forth (default: null)
- `sway_workspace_layout`: Workspace layout - "default", "stacking", or "tabbed" (default: null)
- `sway_default_orientation`: Default orientation - "horizontal" or "vertical" (default: null)
- `sway_default_floating_size`: Default floating size (default: null)
- `sway_force_xwayland`: Force Xwayland (default: null)
- `sway_xwayland_disable`: Disable Xwayland (default: null)
- `sway_title_format`: Title format (default: null)
- `sway_includes`: List of additional config files to include (default: [])

See `defaults/main.yml` for the complete list of all available variables.

## Dependencies

This role depends on:
- `imp1sh.ansible_managemynetwork.ansible_packages` - For package installation

Example Playbook
----------------

Basic usage:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_sway
```

With custom configuration:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_sway
      vars:
        sway_key_mod: "Mod4"
        sway_terminal: "alacritty"
        sway_menu: "rofi -show drun"
        sway_font: "pango:DejaVu Sans 11"
        sway_gaps_inner: 10
        sway_gaps_outer: 5
        sway_outputs:
          - name: "*"
            background_image: "/usr/share/backgrounds/sway/sway_wallpaper.png"
            background_color: "#000000" # alternatively you can specify a color. Image has precedence
            background_mode: "fill" # fill(default) | stretch | fit | center | tile
            mode: "1920x1080"
        sway_inputs:
          - identifier: "*"
            xkb_layout: "us"
            xkb_variant: "intl"
        sway_exec_commands:
          - command: "swaybg -i /usr/share/backgrounds/sway/sway_wallpaper.png"
          - command: "waybar"
```

Configure for a specific user:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_sway
      vars:
        sway_users: "alice"
```

Configure for multiple users:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_sway
      vars:
        sway_users: ["alice", "bob", "charlie"]
```

Use system-wide configuration:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_sway
      vars:
        sway_userconfig: false
```

Custom keybindings:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_sway
      vars:
        sway_keybindings:
          - keys: "$mod+Return"
            command: "exec $term"
          - keys: "$mod+Shift+q"
            command: "kill"
          - keys: "$mod+d"
            command: "exec $menu"
          - keys: "$mod+b"
            command: "exec firefox"
```

Window attributes (marks, floating, workspace assignment):

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_sway
      vars:
        sway_window_attributes:
          Browser:
            - criteria: 'app_id="org.mozilla.firefox"'
              workspace: 2
          Mail:
            - criteria: 'app_id="net.thunderbird.Thunderbird"'
              workspace: 1
```

## Troubleshooting

### Sway configuration validation

After running the role, you can validate the generated configuration:

```bash
swaymsg -t get_tree
```

### Common issues

**Sway not starting after configuration:**

1. Check if the configuration file exists:
   ```bash
   ls -la ~/.config/sway/config
   ```

2. Validate the configuration syntax:
   ```bash
   swaymsg -c ~/.config/sway/config
   ```

3. Check for syntax errors in the configuration:
   ```bash
   swaymsg -t get_tree 2>&1 | grep -i error
   ```

**Configuration not applied:**

1. Check if the role ran successfully:
   ```bash
   ansible-playbook playbook.yml --syntax-check
   ```

2. Verify the configuration file permissions:
   ```bash
   ls -la ~/.config/sway/config
   ```

3. Check the role logs for errors.

**Backup files:**

When the templated config changes, Ansible keeps a backup alongside the live file named `config.<pid>.<YYYY-MM-DD>@<HH:MM:SS>~`. The cleanup timer prunes these (and any leftover `*.backup.*` files) once they exceed `sway_cleanup_age_minutes`. To restore one manually:

```bash
cp ~/.config/sway/config.<pid>.<YYYY-MM-DD>@<HH:MM:SS>~ ~/.config/sway/config
```

## Changelog

### Version 2.0.0 (2026-06-20)

**Improvements:**
- Fixed template syntax errors (missing quotes)
- Added configuration validation
- Improved error handling
- Added file existence checks
- Added backup mechanism for existing configurations
- Added comprehensive documentation
- Improved testing
- Updated to support multiple distributions (Debian)
- Standardized variable naming
- Added troubleshooting section

**Bug Fixes:**
- Fixed hardcoded paths
- Fixed template syntax errors
- Fixed license inconsistency

**Breaking Changes:**
- None

## Cleanup Configuration

This role implements a systemd user timer to automatically clean up backup sway configuration files. When the sway configuration is updated, backups are created with timestamps. The cleanup timer removes these backup files after a specified age.

### Variables

- `sway_cleanup_enable`: Enable/disable automatic cleanup (default: true)
- `sway_cleanup_age_minutes`: Age in minutes for backup files to be deleted (default: 2880 = 2 days)
- `sway_cleanup_timer_schedule`: Systemd timer schedule (default: "Mon *-*-* 10:00:00" - first Monday of month at 10:00)

### How it works

The cleanup functionality:
1. Creates a systemd user timer that runs monthly on the first Monday at 10:00
2. Removes backup files older than the specified age (default 2 days)
3. Automatically runs after system boot if the system was offline during the scheduled time
4. Uses the `find` command to locate and delete old backup files in `~/.config/sway/`

### Customization

To disable cleanup:
```yaml
sway_cleanup_enable: false
```

To change the cleanup age (e.g., 7 days):
```yaml
sway_cleanup_age_minutes: 10080
```

To customize the timer schedule:
```yaml
sway_cleanup_timer_schedule: "Mon *-*-* 09:00:00"
```

## Author Information

This role is part of the ansible_managemynetwork collection.
