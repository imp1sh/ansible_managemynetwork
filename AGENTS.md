# AGENTS.md — ground rules for `imp1sh.ansible_managemynetwork`

This file is the canonical contributor guide for agents (human or AI) working on this
collection. It consolidates the conventions already stated in `README.md` with the
best practices proven by the most polished roles. **Not every existing role satisfies
every rule today.** Treat the rules below as the target state; when you touch a role,
leave it closer to compliance than you found it.

Don't blindly commit AI-generated content. Read it, understand it, verify it. If you
cannot stand behind a change, do not commit it.

## Scope and identity

- Namespace `imp1sh`, collection `ansible_managemynetwork`, abbreviated **MMN**.
- Primary targets: **Debian GNU/Linux** and **OpenWrt**. Other families (Alpine,
  FreeBSD, Arch, EL, Fedora) remain supported where a role already handles them, but
  new work should not broaden the matrix without reason.
- Requires Ansible **>= 2.11** (`meta/runtime.yml`). Per-role `meta/main.yml` must
  declare `min_ansible_version: "2.11"` to match — several roles still say `2.9`,
  fix them when touched.
- Release version stays below `1.x` until every shipped role meets this standard
  (see `README.md` "Maintenance Status"). Production-ready roles are enumerated in
  the README table; unlisted roles are candidates for uplift or removal.

## Reference roles

When in doubt, imitate these three roles — they are the de facto style guide:

- `roles/ansible_packages/`
- `roles/ansible_users/`
- `roles/ansible_groups/`

For OpenWrt roles, `roles/ansible_openwrtsystem/` is the clearest exemplar of the
imagebuilder-aware delegation pattern described below.

## Paradigms (carry forward from README.md)

- **Separation of duty.** A role owns exactly one concern. Package installation is
  the job of `ansible_packages` / `ansible_openwrtpackages`; other roles feed it via
  `*_additional_packages` lists and `include_role`, they do not call `apt`/`opkg`
  themselves. Diverge only when there is genuinely no alternative.
- **Logic lives in roles, not playbooks.** Playbooks should set variables and invoke
  roles; nearly all programmatic behaviour belongs inside the role so callers only
  configure data.
- **Design for portability.** Differences between OSes belong in OS-specific
  variable/task files loaded dynamically — never in sprawling inline `when` chains.
- **Host- and group-scoped variables.** Where a role accepts per-host and per-group
  inputs, expose dedicated `<prefix>_*host` and `<prefix>_*group` keys (soft
  requirement; follow what the reference roles do).
- **Be opinionated only when the opinion is strong and validated**, never out of
  laziness.

## Required role structure

Every role must have, at minimum:

```
roles/<role>/
├── defaults/main.yml      # user-tunable knobs (lowest precedence)
├── meta/main.yml          # galaxy_info + accurate platforms + galaxy_tags
├── README.md              # role purpose, variables, usage, imagebuilder support
└── tasks/
    ├── main.yml           # dispatcher only — guards + include_tasks
    └── NN<name>.yml        # ordered, focused task files (01…, 02…)
```

Add `vars/`, `handlers/`, `templates/`, `files/` as needed.

Rules:

- `tasks/main.yml` is a **dispatcher**: guards, mode selection, and
  `include_tasks`/`include_role` calls. Put substantive work in numbered task files
  (`01live.yml`, `01imagebuilder.yml`, `02…`, `checks.yml`, …). Numbers sort the
  run; names describe the phase.
- Split **live mode** and **imagebuilder mode** into separate task files (see
  "OpenWrt imagebuilder contract").
- Use `vars/` for role-internal constants and OS-specific mappings. Load them
  dynamically with the `first_found` lookup — do not hardcode distribution branches
  in tasks:

  ```yaml
  - name: "MMN <role> - Setting OS variables"
    ansible.builtin.include_vars: "{{ lookup('ansible.builtin.first_found', params) }}"
    vars:
      params:
        files:
          - "{{ ansible_distribution }}.yml"
          - "{{ ansible_os_family }}.yml"
          - default.yml
        paths:
          - "{{ role_path }}/vars"
  ```

  Provide a `vars/default.yml` fallback so the lookup never fails silently.

- Handlers go in `handlers/main.yml`. Guard any handler that touches a live service
  with `when: not <prefix>_runimagebuilder | default(false) | bool` so image builds
  do not attempt to restart daemons that do not exist on the buildhost.

## Naming conventions

- **Variables** are namespaced with a stable domain prefix tied to the role, and
  that prefix is used consistently throughout the role. Existing schemes:
  | Role | Prefix |
  | ---- | ------ |
  | `ansible_packages` | `packages_` |
  | `ansible_users` | `system_users_` |
  | `ansible_groups` | `system_groups_` |
  | `ansible_openwrt*` | `openwrt_<section>_` (e.g. `openwrt_system_`, `openwrt_firewall_`) |
  | `ansible_postgresql` (illustrative) | `psql_` |

  Choose the prefix when introducing a role and stick to it; do not mix
  `packages_` and `system_packages_` inside the same role. Internal/temporary
  facts introduced by a role are prefixed with an underscore, e.g.
  `_openwrt_system_target_host`.

- **Task names** follow `MMN <rolename> - <Short capitalized description>`
  (documented in `README.md`). `<rolename>` is the role name without the leading
  `ansible_` segment, e.g. `MMN packages - …`, `MMN users - …`,
  `MMN openwrtsystem - …`. Keep descriptions brief but sufficient; start with a
  capital letter.

- **Files** are snake_case. Templates use a `.j2` extension.

## Dispatcher / guard pattern (mandatory)

`tasks/main.yml` must guard on the presence of the role's primary input variable
and emit a clear skip message when it is unset. Mirror the reference roles:

```yaml
---
- name: "MMN users - is system_users defined?"
  when: system_users is defined
  block:
    - name: "MMN users - Run live mode"
      ansible.builtin.include_tasks: 01live.yml
      when: (system_users_runimagebuilder is not defined) or
            (system_users_runimagebuilder is defined and not system_users_runimagebuilder)

    - name: "MMN users - Run imagebuilder mode"
      ansible.builtin.include_tasks: 01imagebuilder.yml
      when:
        - system_users_runimagebuilder is defined
        - system_users_runimagebuilder

- name: "MMN users - Fail status feedback"
  ansible.builtin.debug:
    msg: "The role system_users did not run on host {{ inventory_hostname }} because the var system_users is not set."
  when: system_users is not defined
```

Never let a role silently no-op because a variable was forgotten.

## OpenWrt imagebuilder contract (mandatory for all `ansible_openwrt*` roles)

Every OpenWrt-specific role **must** support both operating modes:

1. **Live mode** — applies configuration to a running OpenWrt device (Python is
   installed on the target; files land in real `/etc/config/…` and services reload).
2. **Imagebuilder mode** — renders the identical configuration into the OpenWrt
   Image Builder's `files/` directory on a build host so it gets baked into a
   firmware image. Nothing runs on the target; nothing is installed/restarted.

Compliance can only be confirmed by actually building an image with
`ansible_openwrtimagebuilder` consuming the role — that is the acceptance test.

### Mechanism

The `ansible_openwrtimagebuilder` role's `tasks/prepare.yml` computes
`openwrt_imagebuilder_deployroot` (the absolute path to the image builder's
`files/` directory on the build host) and publishes it as a fact. For backwards
compatibility it also fans that value out to per-role `*_deployroot` facts
(`openwrt_system_deployroot`, `openwrt_network_deployroot`, `cacert_deployroot`,
`podman_deployroot`, `restic_deployroot`, `system_users_setpassword_deployroot`,
…). That fan-out list is legacy scaffolding: **new roles must read
`openwrt_imagebuilder_deployroot` directly** rather than expecting to be added to
the list in `prepare.yml`.

Each OpenWrt role must therefore:

1. Declare deploy-path defaults rooted in a `<prefix>_deployroot` that defaults to
   `"/"` so the same templates resolve correctly in both modes:

   ```yaml
   # defaults/main.yml
   openwrt_system_deployroot: "/"
   openwrt_system_deploypath: "{{ openwrt_system_deployroot }}etc/config"
   openwrt_system_deployfile: "system"
   openwrt_system_deploypath_kernellogging: "{{ openwrt_system_deployroot }}etc/sysctl.d"
   openwrt_system_deployfile_kernellogging: "kernellogging.conf"
   ```

   Never hard-code `/etc/config/...` destinations in tasks or templates — derive
   them from `<prefix>_deployroot` so imagebuilder mode redirects them wholesale.

2. Compute a delegation target at the top of `tasks/main.yml` and route every
   filesystem-writing task through it:

   ```yaml
   - name: "MMN openwrtsystem - Determine target host for delegation"
     ansible.builtin.set_fact:
       _openwrt_system_target_host: >-
         {{
           openwrt_imagebuilder_buildhost
           if (openwrt_imagebuilder_buildhost is defined and openwrt_imagebuilder_buildhost != inventory_hostname)
           else inventory_hostname
         }}
   ```

   Every `ansible.builtin.template`, `ansible.builtin.copy`, `ansible.builtin.file`,
   `ansible.builtin.lineinfile`, etc. in the role carries
   `delegate_to: "{{ _openwrt_system_target_host }}"`.

3. Skip live-only side effects in imagebuilder mode. Two accepted patterns:

   - **Config-rendering roles**: always render templates (they are mode-neutral),
     but guard service-reload handlers with
     `when: not <prefix>_runimagebuilder | default(false) | bool`.
   - **Package-installing roles** (e.g. `ansible_openwrtpackages`): expose a
     `<prefix>_runimagebuilder` boolean and skip the live `opkg`/package-manager
     task when it is true — the image builder injects packages via
     `make image PACKAGES=…`. Feeding that list is the role's job in
     imagebuilder mode.

4. **Prefer templating UCI config files over the `uci` Ansible module.** Templating
   works identically in both modes; the `uci` module only operates against a live
   device and therefore breaks imagebuilder mode. Reserve `uci`/command-based
   interaction for situations where templating is impossible, and confine it to
   live-mode task files.

5. Provide a `checks.yml` (included near the top of `main.yml`) that validates
   role-specific inputs with `ansible.builtin.assert` before anything is rendered
   or applied.

### Acceptance checklist for an OpenWrt role

- [ ] Defaults expose `<prefix>_deployroot` (default `"/"`) and derived
      `<prefix>_deploypath` / `<prefix>_deployfile`.
- [ ] No task/template writes to a literal `/etc/...` path; all paths derive from
      `<prefix>_deployroot`.
- [ ] `tasks/main.yml` sets `_<prefix>_target_host` and every FS-writing task
      `delegate_to`s to it.
- [ ] Handlers (if any) are guarded against `*_runimagebuilder`.
- [ ] Package-management tasks are gated by `<prefix>_runimagebuilder` and feed
      the image builder package list in build mode.
- [ ] Configuration is delivered via Jinja2 templates of the UCI files, not the
      `uci` module.
- [ ] An image built with `ansible_openwrtimagebuilder` boots with the role's
      config present and correct.
- [ ] `README.md` documents the role's imagebuilder support.

## Validation, idempotency and robustness

- **Validate inputs early.** Ship a `checks.yml` included from `main.yml` and use
  `ansible.builtin.assert` with explicit `fail_msg`/`success_msg`, each guarded by
  `when: <var> is defined`. Validate types and value ranges:

  ```yaml
  - name: "MMN openwrtsystem - Validate openwrt_system_log_proto variable"
    ansible.builtin.assert:
      that:
        - (openwrt_system_log_proto | lower == 'tcp') or (openwrt_system_log_proto | lower == 'udp')
      fail_msg: "openwrt_system_log_proto must be either tcp or udp."
      success_msg: "openwrt_system_log_proto seems valid."
    when: openwrt_system_log_proto is defined
  ```

- **Keep idempotency intact.**
  - Pass optional module parameters with `default(omit)` so unset dictionary keys
    do not clobber existing state.
  - Mark cache-refresh tasks `changed_when: false`.
  - Never use `ansible.builtin.command` or `ansible.builtin.shell` without a
    `changed_when` (and ideally a `creates:`/`creates` guard). Existing bare
    `command` usages (e.g. FreeBSD hostname changes) must be made idempotent when
    touched.

- **Filter then act.** For roles driven by a host-/group-keyed dictionary, first
  initialise an empty accumulator, loop the input appending matching entries with
  `set_fact`, then loop the accumulator to act. This mirrors `ansible_users` and
  makes the run legible and debuggable.

- **Use `loop` with `loop_control`.** Name the loop variable to avoid colliding
  with the default `item`:

  ```yaml
  loop: "{{ system_users | dict2items }}"
  loop_control:
    loop_var: user
  ```

- **Debuggability.** Add debug tasks printing intermediate state, gated by the
  collection-wide boolean `mmn_verbose` (default false). Leave them in — they cost
  nothing when off and save hours when on.

## Formatting (normalize on edit)

These rules exist because the collection currently mixes styles. Apply them to any
file you touch; do not mass-reformat untouched files in the same change as a
functional edit (keep diffs reviewable).

- Begin every YAML file with `---`.
- Indent two spaces. **No tabs in YAML.** (Tabs inside generated config templates
  are fine when the target format requires them.)
- Use **FQCN** for every module: `ansible.builtin.set_fact`, `ansible.builtin.user`,
  `ansible.builtin.template`, … — never the short forms.
- Use the modern `loop:` keyword with `loop_control`. **Do not introduce
  `with_items` / `with_dict` / `with_filetree` / `with_first_found`**; migrate
  existing occurrences when you touch the file.
- Prefer `query()` / `lookup()` over `with_*` equivalents.
- Double-quote string scalars and Jinja expressions used as strings; leave numeric
  booleans/lists unquoted. Quote file modes as strings (`mode: "0755"`).
- Fold long `when` conditions with `>` / `>-` and align continuation lines.
- One blank line between tasks for readability (per `README.md`).
- Comment with a single `#`; reserve `##` for Markdown headings. **Delete stale
  copy-pasted scaffolding** such as `# defaults file for ansible_sysctl` left in
  unrelated roles, commented-out dead tasks, and TODOs that have no owner/date.
  If you must leave a TODO, include a pointer to an issue.
- Trim trailing whitespace; end files with a single newline.

## Meta and documentation hygiene

- Every role keeps `meta/main.yml` with `galaxy_info` populated: `author`,
  `description`, `company`, `issue_tracker_url`, `license` (BSD-3-Clause),
  `min_ansible_version: "2.11"`, `platforms`, and `galaxy_tags`.
- `platforms` must reflect reality. Spell the OpenWrt platform as **`OpenWrt`**
  consistently (existing roles mix `OpenWrt` / `OpenWRT` — normalize on edit).
  Drop EOL platforms (e.g. EL 5/6) when you touch a role.
- Every role ships a `README.md` documenting purpose, variables, and — for OpenWrt
  roles — its imagebuilder-mode support. Keep the collection-root `README.md`
  production-readiness table in sync with reality.
- Do not ship empty placeholder files. If `defaults/main.yml` would be empty,
  either populate it with the role's real defaults (preferred) or omit the file;
  do not leave a stray `# defaults file for …` stub.

## Testing expectations

- Test the happy path **and** corner cases: missing optional variables, empty
  lists, both OS families the role claims, and — for OpenWrt roles — both live and
  imagebuilder modes.
- For OpenWrt roles, the proof of imagebuilder support is a successful image build
  via `ansible_openwrtimagebuilder` that includes the role's output. CI/manual
  verification should exercise this.
- Re-run any role-specific sanity available (`ansible-playbook --syntax-check`,
  `--check`, lint with `ansible-lint` if configured) before submitting.

## Known deviations to remediate opportunistically

This list is illustrative, not exhaustive — discover more by diffing against the
reference roles.

- Several OpenWrt roles hard-code `/etc/config/...` destinations instead of
  deriving from `<prefix>_deployroot`, breaking imagebuilder mode.
- Some OpenWrt roles lack the `_<prefix>_target_host` delegation fact and the
  `delegate_to` on file tasks.
- `ansible_openwrtimagebuilder/tasks/prepare.yml` maintains a hand-written fan-out
  list of `*_deployroot` fact names; new roles should consume
  `openwrt_imagebuilder_deployroot` directly so this list stops growing.
- `ansible_openwrtpackages/defaults/main.yml` is an empty stub.
- A number of roles carry leftover `# defaults file for ansible_sysctl`-style
  headers copied from unrelated roles.
- Bare `ansible.builtin.command` invocations (e.g. `ansible_hostname` on FreeBSD)
  lack `changed_when`/`creates` and are not idempotent.
- Deprecated `with_*` loops survive in archived/test scenarios; migrate on contact.
- `min_ansible_version` in per-role `meta/main.yml` lags the collection's
  `requires_ansible: ">=2.11"`.
- Platform spelling (`OpenWrt` vs `OpenWRT`) and EOL platform entries need tidying.

When fixing any of the above, restrict the change to the role at hand so reviewers
can reason about it; raise a follow-up issue for systemic rollouts.
