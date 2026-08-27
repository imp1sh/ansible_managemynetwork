# imp1sh.ansible_managemynetwork.ansible_aptrepos

Manages APT repositories and base sources on Debian-family hosts (Debian, Ubuntu, Raspberry Pi OS). Handles third-party repos with GPG key download/dearmoring and controls `/etc/apt/sources.list` content.

Counterpart to `ansible_dnfrepos` (which does the same for Red Hat-family/DNF).

## What it does

| Step | Action |
|------|--------|
| **1. Validate** | Asserts each repo has a `repo` line and that `key_path` is set when `key_url` is provided |
| **2. Keys** | Downloads GPG keys via `get_url`, dearmors with `gpg --dearmor`, installs to `key_path` |
| **3. Repos** | Adds/removes APT repository lines via `ansible.builtin.apt_repository` |
| **4. Sources** | Writes `/etc/apt/sources.list` from the `apt_sources` list (when defined) |
| **5. Cache** | Optionally runs `apt-get update` |

Does NOT use the deprecated `apt-key` — uses the modern `signed-by=` keyring path.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `apt_repos` | `{}` | Dict of third-party repos to manage (see below) |
| `apt_sources` | `[]` | List of lines for `/etc/apt/sources.list` (empty = untouched) |
| `apt_repos_update_cache` | `false` | Run `apt-get update` after changes |
| `apt_repos_keyring_owner` | `root` | Owner of GPG keyrings |
| `apt_repos_keyring_group` | `root` | Group of GPG keyrings |
| `apt_repos_keyring_mode` | `0644` | Permissions of GPG keyrings |
| `apt_sources_owner` | `root` | Owner of `/etc/apt/sources.list` |
| `apt_sources_group` | `root` | Group of `/etc/apt/sources.list` |
| `apt_sources_mode` | `0644` | Permissions of `/etc/apt/sources.list` |

### apt_repos

Dict keyed by a stable name that doubles as the sources filename stem (`<name>.list`).

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `repo` | yes | — | Full apt sources line (`deb [signed-by=...] url dist comps`) |
| `key_url` | no | — | URL to download the GPG key from |
| `key_path` | required if `key_url` | — | Where to install the dearmored keyring |
| `state` | no | `present` | `present` or `absent` |
| `filename` | no | dict key | Sources filename stem (`<filename>.list`) |

```yaml
apt_repos:
  example:
    repo: "deb [signed-by=/usr/share/keyrings/example-archive-keyring.gpg] https://apt.example.net/ stable main"
    key_url: "https://apt.example.net/key.gpg"
    key_path: "/usr/share/keyrings/example-archive-keyring.gpg"

  # Repo without GPG key management (key already in trust store)
  backports:
    repo: "deb http://deb.debian.org/debian trixie-backports main"
    filename: trixie-backports
```

### apt_sources

List of lines for `/etc/apt/sources.list`. When non-empty, the role writes the file from this list, replacing any existing content (with backup). When empty, the file is left untouched.

```yaml
apt_sources:
  - "# Debian Trixie"
  - "deb http://debian.netcologne.de/debian/ trixie main non-free-firmware"
  - "deb http://debian.netcologne.de/debian/ trixie-updates main non-free-firmware"
  - "deb http://security.debian.org/debian-security trixie-security main non-free-firmware"
  - "deb http://deb.debian.org/debian trixie-backports main contrib non-free"
```

## Removal

Set `state: absent` on any `apt_repos` entry. The repo line is removed and the GPG key/keyring is cleaned up. To stop managing sources, set `apt_sources` to `[]`.

## Usage

In `group_vars/os_server_debian.yml`:

```yaml
apt_repos:
  example-third-party:
    repo: "deb [signed-by=/usr/share/keyrings/example-archive-keyring.gpg] https://apt.example.net/ stable main"
    key_url: "https://apt.example.net/key.gpg"
    key_path: "/usr/share/keyrings/example-archive-keyring.gpg"

apt_sources:
  - "deb http://debian.netcologne.de/debian/ trixie main non-free-firmware"
  - "deb http://debian.netcologne.de/debian/ trixie-updates main non-free-firmware"
  - "deb http://security.debian.org/debian-security trixie-security main non-free-firmware"
```

Playbook:

```yaml
- hosts: os_server_debian
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_aptrepos
```

## Relationship to ansible_dnfrepos

`ansible_dnfrepos` serves Red Hat-family hosts (Fedora, RHEL, CentOS, Rocky, AlmaLinux). `ansible_aptrepos` serves Debian-family hosts (Debian, Ubuntu, Raspberry Pi OS). Both follow the same architectural pattern: validate, manage keys, manage repos, optionally refresh cache. Steer which repos land on which hosts via group_vars.

## Idempotency

`get_url` (key download), `gpg --dearmor` (key conversion, gated on download change), `apt_repository`, and `copy` (sources.list) are all idempotent. Repeated runs converge without producing duplicate entries or stacked keyrings.
