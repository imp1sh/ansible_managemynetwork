# imp1sh.ansible_managemynetwork.ansible_users

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_users)

This role manages users for hosts.
It currently supports those Operating Systems:
- Debian
- Ubuntu
- Alpine
- Archlinux
- CentOS / RHEL / Rocky / Alma (EL)
- Fedora
- FreeBSD
- OpenWrt

## OpenWrt specific
When using this with OpenWrt it will install those packages so ansible.builtin.user can do its job:
- shadow-useradd
- shadow-userdel
- shadow-usermod
- sudo

Usually in OpenWrt only the root user is being used but it's actually possible to add additional users, e.g. for backup jobs or whatever. This role is also compatible  with [ansible_openwrtimagebuilder](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_openwrtimagebuilder/README.md). It works by deploying an init script into `/etc/uci-defaults/` on the built image that runs once at first boot, creating or updating the user and setting their password.

### Security considerations for imagebuilder mode
The uci-defaults init script contains the user's password hash in cleartext. Until the device completes its first boot and the script is consumed (executed and deleted by OpenWrt), the hash is embedded in the firmware image artifact. Anyone who obtains the built image **before** first boot can extract the hashes. Although the passwords themselves are hashed (SHA-512), the hashes are crackable offline. Treat built images as sensitive artifacts:
- Store and transfer them over secure channels.
- Restrict access to the build host and image storage.
- Use `ansible-vault` to encrypt the `system_users` variable definitions so the hashes are not visible in your playbook repository.

If you do `import_playbook` on the users role but you only want it to run on OpenWrt, use:
```yaml
- name: MMN users
  import_playbook: users.yml
  when: ansible_distribution == 'OpenWrt'
```
while the users playbook looking like this:
```yaml
---
- name: Handling users in Linux, Unix
  hosts: all
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_users
```

## Role toggles

| Variable | Default | Description |
|----------|---------|-------------|
| `system_users` | _(unset)_ | Dictionary of users to manage. The role does nothing if this is unset. |
| `system_users_runimagebuilder` | `false` | Set to `true` to run in imagebuilder mode (deploys uci-defaults init scripts to the build host instead of managing users live). |
| `system_users_additional_packages` | _(OpenWrt only)_ | List of extra packages to install via the `ansible_packages` role. Defined per-OS in `vars/`; on OpenWrt this is `shadow-useradd`, `shadow-userdel`, `shadow-usermod`, `sudo`. Override to add more. |
| `system_users_setpassword_deployroot` | _(unset, imagebuilder mode)_ | Root directory on the build host where the uci-defaults scripts are deployed. Required for imagebuilder mode — typically set to the OpenWrt imagebuilder output directory (e.g. `/tmp/openwrt-imagebuilder/build_dir/target-armvirt_cortex-a15/root-ext4`). |
| `system_users_setpassword_deployfile` | `99-set-password` | Filename prefix for the uci-defaults init script. Final path is `{deployroot}/etc/uci-defaults/{deployfile}-{username}`. |
| `system_users_enable_checks` | `true` | When `true`, validates `system_users` structure and password hashes before applying anything. Set to `false` to skip all input validation. See [Input validation](#input-validation). |

## Input validation

When `system_users_enable_checks` is `true` (the default), the role validates its inputs before touching any host:

- `system_users` must be a dict (rejects scalars, lists, `null`).
- Each user entry must be a dict with a valid `state` (`present` or `absent`).
- Sequence-typed fields (`groups`, `deployfiles`) must be lists, not strings.
- Mapping-typed fields (`groups_byhostname`) must be dicts.
- `system_users_create_on_hosts` and `system_users_create_on_hostgroups` if defined must be dicts.
- Every `password` field must be a hash (modular crypt format `$<id>$...`) or a lock marker (`!`, `!!`, `*`). Plaintext passwords are rejected — this catches the common mistake of vault-encrypting a plaintext password instead of a hash.
- On OpenWrt targets (live or imagebuilder mode), password hashes are additionally checked for musl compatibility. Yescrypt (`$y$`), bcrypt (`$2a$`/`$2b$`/`$2y$`), scrypt (`$7$`), gost-yescrypt (`$gy$`), and the `rounds=` parameter are rejected. See [OpenWrt password hash constraints](#openwrt-password-hash-constraints).

Validation failures abort the play with a descriptive message naming the offending user and the failing condition. To bypass validation entirely, set `system_users_enable_checks: false`.

## Variables

Since you don't want to define your users for every host individually, you need to place your variable somewhere every host has access to it. In this example the `system_users` variable will be defined in the scope of an Ansible group called tags_allhosts.

`./group_vars/tags_allhosts.yaml`
```yaml
system_users:
  jdenker:
    comment: "Johann Denker"
    uid: 2048
    password: "$6$6FlXAIFWM2v1clqj$pVYUclQuCJ0kDDcg2QFhjgfhjg31rt4FmS8cVKUxsDKSOmasdfasdfasdfaqcQJECEpaiCjasdfsadfm0GxRtsmCNoTh/mlIp9gQDGr97pvUhswZOieSi0"
    shell: "bash"
  "skuchen":
    comment: "Sibille Kuchen"
    uid: 2050
    password: "$6$clsF9Lxzh9JF5LZJ$RhUnTHwDHiLwrLjIkFj2.K0BHh632465gi95g6JSe0BsdafsdfaoCs6141.sA3hz32RGtvMiLXn4NhgfdhjmhsX.zXu4ozlIQTaoQL2xuP9I/"
    shell: "zsh"
```

The password must be a **hash**, never plaintext. The role validates this at runtime (see [Input validation](#input-validation)) and refuses to apply a plaintext password, because storing one in `/etc/shadow` breaks authentication on every target OS.

### Generating a password hash

Use SHA-512 (`$6$`) — it is the strongest widely-supported method and works on all supported operating systems including OpenWrt:

```bash
mkpasswd --method=sha-512
```

Enter the desired password when prompted. The command prints a hash beginning with `$6$`. Paste that string (quotes and all) into the `password` field.

Alternatively, generate a hash non-interactively with an explicit salt:

```bash
mkpasswd --method=sha-512 --salt='yourrandomsalt'
```

To disable password login without removing the account, use a lock marker instead of a hash:

```yaml
system_users:
  monitoring:
    password: "!"
```

### Encrypting the hash with ansible-vault

The hash itself is sensitive — anyone with the hash can attempt offline cracking. Protect it with `ansible-vault`.

**Correct order:** hash first, then encrypt the file or variable containing the hash.

```bash
# 1. Generate the hash
mkpasswd --method=sha-512
# Output: $6$AbCdEf123...$...  ← copy this

# 2. Put it in your variables file
#    ./group_vars/all.yml
#    system_users:
#      jdenker:
#        password: "$6$..."

# 3. Encrypt the file
ansible-vault encrypt ./group_vars/all.yml
```

**Common mistake:** encrypting the plaintext password instead of the hash. If you run `ansible-vault encrypt_string` on a plaintext password and paste the resulting `!vault` blob into the `password` field, the decrypted plaintext — not a hash — ends up in `/etc/shadow`. Authentication silently breaks on every target. The role's input validation catches this and fails before any harm is done, but the correct workflow is to hash first, then vault-encrypt the hash.

**Shell quoting pitfall:** SHA-512 hashes contain `$` delimiters (e.g. `$6$salt$hash`). If you pass such a hash to `ansible-vault encrypt_string` in **double quotes**, the shell expands `$6`, `$salt`, etc. as (empty) variables and strips them, corrupting the value. Always use **single quotes**:

```bash
# WRONG — shell eats the $ segments
ansible-vault encrypt_string "$6$AbCdEf$....." --name system_users_root_password

# CORRECT — single quotes preserve $ literally
ansible-vault encrypt_string '$6$AbCdEf$.....' --name system_users_root_password
```

### OpenWrt password hash constraints

OpenWrt uses **musl libc**, whose `crypt()` supports a subset of the algorithms available on glibc-based distributions:

| Algorithm | Prefix | OpenWrt (musl) | Desktop/Server (glibc) |
|-----------|--------|---------------|----------------------|
| SHA-512 | `$6$` | supported | supported |
| SHA-256 | `$5$` | supported | supported |
| MD5 | `$1$` | supported | supported |
| DES | _(13-char, no prefix)_ | supported | supported |
| yescrypt | `$y$` | **unsupported** | default on Fedora 36+, RHEL 9, Debian bookworm |
| bcrypt | `$2a$`/`$2b$`/`$2y$` | **unsupported** | supported (libxcrypt) |
| scrypt | `$7$` | **unsupported** | supported (libxcrypt) |
| gost-yescrypt | `$gy$` | **unsupported** | supported (libxcrypt) |

Additionally, the `rounds=` parameter inside a SHA-512/SHA-256 hash (e.g. `$6$rounds=656000$salt$hash`) behaves **inconsistently** between glibc and musl — glibc honours the iteration count, musl treats it as part of the salt, producing a different hash. Login fails silently.

Because modern desktop and server distributions default to yescrypt, a hash generated on your workstation with `passwd` or `mkpasswd` (without `--method`) may be a `$y$` hash that is unusable on OpenWrt.

**Always generate OpenWrt passwords with an explicit method:**

```bash
mkpasswd --method=sha-512
```

The role's input validation rejects yescrypt, bcrypt, scrypt, gost-yescrypt, and `rounds=` hashes when the target is OpenWrt (detected via `ansible_distribution == "OpenWrt"` or imagebuilder mode). On non-OpenWrt targets these algorithms are permitted.

A more complete list of available options can be found in the [role's documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html).

This role has a dependency to [imp1sh.ansible_managemynetwork.ansible_packages](/junicast/docs/AnsibleManagemynetworkCollection/rolePackages) and will install the shell package you choose for the users automatically.

### User attributes

Each key in `system_users` is the username. The value is a dictionary of attributes forwarded to [`ansible.builtin.user`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html). Attributes not listed below are passed through with sensible defaults — see the module docs for the full list.

| Attribute | Type | Description |
|-----------|------|-------------|
| `comment` | string | GECOS / full name |
| `uid` | int | Numeric user ID |
| `password` | string | Hashed password (use `mkpasswd --method=sha-512`). See [Generating a password hash](#generating-a-password-hash) and [OpenWrt password hash constraints](#openwrt-password-hash-constraints). |
| `shell` | string | Shell binary name (not full path), e.g. `zsh`, `bash`, `fish`, `nologin`, `false`. The role maps this to the correct path per-OS. |
| `home` | string | Home directory path |
| `group` | string | Primary group name |
| `groups_byhostname` | dict | Per-host supplementary groups. Keyed by `inventory_hostname`; value is a list of group names. Example: `groups_byhostname: { router1: [admin, wheel] }` |
| `append` | bool | If `true`, supplementary groups are appended instead of replacing existing memberships |
| `create_home` | bool | If `false`, skip home directory creation |
| `state` | string | `present` (default) or `absent` (removes the user) |
| `generate_ssh_key` | bool | Generate an SSH keypair for the user |
| `expires` | int | Password expiry epoch timestamp |
| `password_expire_max` | int | Maximum days between password changes |
| `password_expire_min` | int | Minimum days between password changes |
| `password_lock` | bool | Lock the password |
| `move_home` | bool | Move home directory if `home` changes |
| `non_unique` | bool | Allow non-unique UIDs |
| `system` | bool | Create as system user |
| `remove` | bool | With `state: absent`, remove home and mail spool |
| `force` | bool | With `state: absent`, forcefully remove even if logged in |
| `update_password` | string | `always` (default) or `on_create` |
| `deployfiles` | list | Optional list of files to deploy into the user's home. Each item is a dict with `src` (relative to `files/`), `dest` (absolute path), and `state` (`present` or `absent`). Deployed as the user via `become_user`. Example below. |

#### deployfiles example
```yaml
system_users:
  jdenker:
    [...]
    deployfiles:
      - src: zshrc_default
        dest: /home/jdenker/.zshrc
        state: present
      - src: screenrc_default
        dest: /home/jdenker/.screenrc
        state: present
      - src: old_config
        dest: /home/jdenker/.oldconfig
        state: absent
```

## Host association
Whether or not a users id deployed on a system is defined within `system_users_create_on_hosts` and `system_users_create_on_hostgroups`. First one for defining on an individual host basis, second one on a group level. Here is an example:

```yaml
system_users_create_on_hosts:
  mmustermann:
    - "accounting.example.com"
  sibilledegenhard:
    - "accounting.example.com"
  user1:
    - "xps13.example.com"
    - "macbook.example.com"
  scan:
    - "nas.example.com"
system_users_create_on_hostgroups:
  ansible:
    - "tags_allhosts"
  sysadm_recovery:
    - "tags_allhosts"
  backupuser:
    - "tags_backuptarget_borg"
```

The group names correspond to the group names in Ansible, here it's a dynamic Netbox inventory using netbox tags.

## Remove Users
Just set the `state` attribute of the user to `absent`. If the attribute `state` is not defined it will default to present.

## Shell
You do not give the full path to the shell here, but only the binary name, e.g. `zsh`. Supported shells vary by OS; common ones are `bash`, `zsh`, `sh`, `fish`, `nologin`, and `false`. If your OS doesn't work with this role or a shell you want is missing, please open [an issue](https://github.com/imp1sh/ansible_managemynetwork/issues).

[Here is](https://github.com/imp1sh/ansible_managemynetwork/blob/main/roles/ansible_users/vars/Debian.yml) a list of supported shells so far.
