Role Name
=========

ansible_screen - Installs GNU screen and deploys a per-user or system-wide screenrc.

Philosophy
----------

The role emits **nothing** by default. Screen reads `/etc/screenrc` (shipped by the distro) then `~/.screenrc`; with empty defaults the user's `~/.screenrc` is absent of overrides and screen falls through to the distro/package defaults. Every opinionated setting is therefore opt-in via `screen_configs` / `screen_defaults`.

Requirements
------------

- Ansible 2.9 or higher
- Depends on `imp1sh.ansible_managemynetwork.ansible_packages` for package installation

Role Variables
--------------

### Deployment mode

- `screen_userconfig` (default `true`): `true` deploys a per-user `~/.screenrc` for every user in `screen_users`; `false` deploys a single system-wide screenrc at `screen_system_dest`.
- `screen_users` (default `null`): target user(s) for per-user mode.
  - `null`/undefined: the user Ansible connects as (`ansible_user`)
  - a string: that single user
  - a list: every user in the list
- `screen_system_dest` (default `/etc/screenrc`): destination for system-wide mode.
- `screen_system_config` (default `{}`): overrides for system-wide mode, same shape as a `screen_configs` entry; merged over `screen_defaults`.

### Per-user configuration (`screen_configs`)

Dict keyed by username; each entry is merged over `screen_defaults` (recursive merge). Parallels `thunar_configs` / `swaylock_configs`. A user listed in `screen_users` but absent from `screen_configs` gets the pure `screen_defaults`.

Shape of a user entry (every key optional):

- `settings` — dict of scalar screen settings, e.g. `{ vbell: "on", defscrollback: 10000 }`. Rendered as `<key> <value>` lines. Booleans may be passed as `true`/`false` (rendered `on`/`off`) or as the strings `"on"`/`"off"`. Unset keys inherit `/etc/screenrc` and screen's compiled defaults.
- `terminal_settings` — literal block string of `termcap` / `terminfo` / `termcapinfo` lines.
- `keybindings` — literal block string of `bind` / `unbindkey` / `register` lines.
- `startup_windows` — literal block string of `screen -t ...` lines.
- `extra` — literal block string of arbitrary extra screenrc lines (e.g. `hardstatus alwayslastline "..."`).

### Base defaults (`screen_defaults`)

Applied to every user / system file; all empty by default so the role emits nothing:

```yaml
screen_defaults:
  settings: {}
  terminal_settings: ""
  keybindings: ""
  startup_windows: ""
  extra: ""
```

Override per user via `screen_configs`, or globally by editing `screen_defaults`.

Dependencies
------------

- `imp1sh.ansible_managemynetwork.ansible_packages`

Example Playbook
----------------

Minimal (installs screen, deploys empty `~/.screenrc` inheriting distro defaults):

```yaml
- name: Install and configure screen
  hosts: os_linux_all
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_screen
```

With per-user opinionated settings:

```yaml
- hosts: workstations
  become: true
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_screen
      vars:
        screen_users: ["jochen", "alice"]
        screen_configs:
          jochen:
            settings:
              vbell: "on"
              autodetach: "on"
              startup_message: "off"
              defscrollback: 10000
              truecolor: "on"
            terminal_settings: |
              termcapinfo xterm* OL=100
              termcapinfo xterm* be
            keybindings: |
              bind 'K' kill
              bind '}' history
            startup_windows: |
              screen -t t14
            extra: |
              hardstatus alwayslastline "%H %-Lw%{= BW}%50>%n%f* %t%{-}%+Lw%"
          alice:
            settings:
              defscrollback: 50000
```

System-wide configuration:

```yaml
- hosts: servers
  become: true
  roles:
    - role: imp1sh.ansible_managemynetwork.ansible_screen
      vars:
        screen_userconfig: false
        screen_system_config:
          settings:
            defscrollback: 5000
            vbell: "on"
```

Notes
-----

- `truecolor` is recognized by screen >= 5.0. Older releases (e.g. Debian's 4.09.x) print a harmless "unknown command" warning at startup. Scope accordingly.
- YAML coerces bare `on`/`off`/`yes`/`no` to booleans; always quote such string values, e.g. `vbell: "on"`.

License
-------

MIT-0

Author Information
-------------------

This role is part of the ansible_managemynetwork collection.
