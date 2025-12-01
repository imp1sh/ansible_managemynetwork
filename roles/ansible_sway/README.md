# imp1sh.ansible_managemynetwork.ansible_packages

Ansible role for managing the Sway window manager

This role installs and configures the Sway window manager on Linux systems. 

## Requirements

- Ansible 2.9 or higher
- Fedora 43
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

- `sway_mod_key`: Modifier key (default: "Mod4" - Super/Windows key)
- `sway_terminal`: Terminal emulator command (default: "alacritty")
- `sway_menu`: Application launcher/menu command (default: "rofi --show drun")
- `sway_font`: Font specification (default: "pango:Monospace 10")

#### Output Configuration

Configure display outputs using the `sway_outputs` list:

```yaml
sway_outputs:
  - name: "*"
    background_image: "/usr/share/backgrounds/sway/sway_wallpaper.png"
    background_mode: "fill" # [ fill(default) | stretch | fit | center | tile ]
    background_color: "#000000" # alternatively you can specify a color. Image has precedence
    mode: "1920x1080"
    position: "0,0"
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

All color variables are prefixed with `sway_colors_`:

- `sway_colors_background`: Background color
- `sway_colors_statusline`: Statusline color
- `sway_colors_separator`: Separator color
- `sway_colors_focused_*`: Colors for focused windows/workspaces
- `sway_colors_inactive_*`: Colors for inactive windows/workspaces
- `sway_colors_urgent_*`: Colors for urgent windows/workspaces
- `sway_colors_binding_mode_*`: Colors for binding mode

See `defaults/main.yml` for the complete list of color variables.

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
      workspace: "current"
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

#### Window Commands

Apply commands to windows matching criteria using the `sway_window_commands` list:

```yaml
sway_window_commands:
  - criteria: "class:Firefox"
    command: "floating enable"
  - criteria: "title:.*"
    command: "border pixel 2"
```

#### Floating Windows

Define floating window criteria using the `sway_floating_criteria` list:

```yaml
sway_floating_criteria:
  - criteria: "class:Pavucontrol"
  - criteria: "class:nm-applet"
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
- `sway_default_border`: Default border style (default: null)
- `sway_default_floating_border`: Default floating border style (default: null)
- `sway_default_floating_size`: Default floating size (default: null)
- `sway_default_floating_position_center`: Center floating windows (default: null)
- `sway_hide_cursor_when_typing`: Hide cursor when typing (default: null)
- `sway_force_display_power_on`: Force display power on (default: null)
- `sway_force_xwayland`: Force Xwayland (default: null)
- `sway_xwayland_disable`: Disable Xwayland (default: null)
- `sway_xwayland_scale`: Xwayland scale (default: null)
- `sway_xwayland_scale_filter`: Xwayland scale filter (default: null)
- `sway_title_format`: Title format (default: null)
- `sway_title_align`: Title alignment (default: null)
- `sway_includes`: List of additional config files to include (default: [])

See `defaults/main.yml` for the complete list of all available variables.

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
    - role: imp1sh.ansible_managemynetwork.ansible_sway
```

With custom configuration:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_sway
      vars:
        sway_mod_key: "Mod4"
        sway_terminal: "alacritty"
        sway_menu: "rofi -show drun"
        sway_font: "pango:DejaVu Sans 11"
        sway_gaps_inner: 10
        sway_gaps_outer: 5
        sway_outputs:
          - name: "*"
            background_image: "/usr/share/backgrounds/sway/sway_wallpaper.png"
            background_color: "#000000" # alternatively you can specify a color. Image has precedence
            background_mode: [ fill(default) | stretch | fit | center | tile ]
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

Window assignments:

```yaml
- hosts: workstations
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_sway
      vars:
        sway_assignments:
          - criteria: "class:Firefox"
            workspace: "1"
          - criteria: "class:Thunderbird"
            workspace: "2"
          - criteria: "class:Code"
            workspace: "3"
```

License
-------

MIT-0

Author Information
------------------

This role is part of the ansible_managemynetwork collection.
