# imp1sh.ansible_managemynetwork.ansible_dnfrepos

Flexibly adds and removes third-party DNF repositories on Red Hat-family hosts (Fedora, RHEL, CentOS Stream, Rocky, AlmaLinux). Driven entirely by a single `dnf_repos` dictionary you set in `group_vars`/`host_vars`, so which repos land on which hosts follows your group assignments.

Compatible with **dnf4 and dnf5** transparently. Skips gracefully on non-RedHat-family hosts.

## Why not `dnf config-manager addrepo`?

Adding a repo from a remote `.repo` file is traditionally done with:

```
# dnf5
sudo dnf config-manager addrepo --from-repofile=https://repo.librewolf.net/librewolf.repo
# dnf4
sudo dnf config-manager --add-repo https://repo.librewolf.net/librewolf.repo
```

Those two forms diverge between dnf generations **and** are non-idempotent: every rerun piles up duplicates (`librewolf.repo`, `librewolf.repo.1`, `librewolf.repo.2`, …) with a filename dictated by the server-side path. Neither property is acceptable for an Ansible role meant to converge.

Instead this role:

1. Drops the `.repo` file straight into `/etc/yum.repos.d/<name>.repo` via `ansible.builtin.get_url` — idempotent, fixed filename — **or**
2. Declares the repo inline via `ansible.builtin.yum_repository` — full control over every knob.

Both produce ordinary `.repo` files that dnf4 and dnf5 interpret identically, so the dnf-generation split disappears completely. GPG keys declared via `gpgkey` are imported with `ansible.builtin.rpm_key` (unless you turn that off).

## Two modes

Every entry in `dnf_repos` is keyed by a stable name that doubles as the `.repo` filename stem (`<name>.repo`). An entry is either **Mode A** (fetch a remote file) or **Mode B** (declare inline):

### Mode A — fetch a remote `.repo` file as-is

Best when the upstream hands you a ready-made `.repo` (LibreWolf, Docker, etc.).

```yaml
dnf_repos:
  librewolf:
    url: "https://repo.librewolf.net/librewolf.repo"
    # optional extras:
    gpgkey: "https://repo.librewolf.net/fedora/$releasever/$basearch/repodata/repomd.xml.key"
    state: present              # set 'absent' to remove
    filename: librewolf        # optional override of the <key>.repo stem
```

### Mode B — declare the repo inline

Full control; mirrors `ansible.builtin.yum_repository` parameters.

```yaml
dnf_repos:
  google-chrome:
    name: "google-chrome"                              # repo id ([..]), defaults to the key
    description: "Google Chrome stable"                # human-readable Name=
    baseurl: "https://dl.google.com/linux/chrome/rpm/stable/$basearch"
    gpgkey: "https://dl.google.com/linux/linux_signing_key.pub"
    gpgcheck: true
    enabled: true
    priority: 10
    exclude: "kernel*"
    state: present
```

Mixing `url` with `baseurl`/`metalink`/`mirrorlist` in one entry is rejected — `url` denotes Mode A.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `dnf_repos` | `{}` | Dict of repos to manage (see above). Keyed by repo name / filename stem. |
| `dnf_repos_import_gpg_keys` | `true` | Import `gpgkey` URLs into the rpm DB via `rpm_key`. Disable to let dnf import lazily. |
| `dnf_repos_refresh_cache` | `false` | Run `dnf makecache` after changes so metadata is ready immediately. |
| `dnf_repos_repo_dir` | `/etc/yum.repos.d` | Destination directory for `.repo` files. |
| `dnf_repos_owner` | `root` | Owner of placed `.repo` files. |
| `dnf_repos_group` | `root` | Group of placed `.repo` files. |
| `dnf_repos_mode` | `0644` | Permissions of placed `.repo` files. |

### Inline (Mode B) per-entry knobs

These map 1:1 onto `ansible.builtin.yum_repository` and are all optional (module defaults apply when omitted): `name`, `description`, `baseurl`, `metalink`, `mirrorlist`, `enabled`, `gpgcheck`, `gpgkey`, `repo_gpgcheck`, `priority`, `exclude`, `includepkgs`, `proxy`, `sslverify`, `protect`, `module_hotfixes`, `state`, `filename`.

## Removal

Set `state: absent` on any entry. Mode A deletes `<name>.repo`; Mode B removes the corresponding stanza.

## Usage

Steer per group in `group_vars/os_desktop_fedora.yml`:

```yaml
dnf_repos:
  librewolf:
    url: "https://repo.librewolf.net/librewolf.repo"
  google-chrome:
    name: "google-chrome"
    description: "Google Chrome stable"
    baseurl: "https://dl.google.com/linux/chrome/rpm/stable/$basearch"
    gpgkey: "https://dl.google.com/linux/linux_signing_key.pub"
    gpgcheck: true
    enabled: true
```

Then apply the role from a play targeting the desired group:

```yaml
- hosts: os_desktop_fedora
  roles:
    - imp1sh.ansible_managemynetwork.ansible_dnfrepos
```

### Layering / extending per host

Stock Ansible replaces (not deep-merges) a dict overridden in a higher-precedence layer. To **add** a repo on top of the group-set without losing the others, compose with `combine`:

```yaml
# host_vars/myhost.yml
dnf_repos: "{{ dnf_repos | combine({'docker-ce': {'name': 'docker-ce', 'description': 'Docker CE', 'baseurl': 'https://download.docker.com/linux/fedora/$releasever/$basearch/stable', 'gpgkey': 'https://download.docker.com/linux/fedora/gpg', 'gpgcheck': true}}) }}"
```

## Idempotency

`get_url`, `yum_repository`, `rpm_key`, and `file` are all idempotent, so repeated runs converge without producing duplicate `.repo` files — the central reason this role avoids `dnf config-manager`.
