# imp1sh.ansible_managemynetwork.ansible\_garage

Deploys [Garage](https://garagehq.deuxfleurs.fr/) — an S3-compatible object
storage server — as a single-node Podman container, paired with the
`ansible_podman` role's plugin system (mirrors `ansible_blocky`).

## Design

* The **structural** Garage config (`metadata_dir`, `data_dir`, `db_engine`,
  `replication_factor`, bind addresses, `s3_region`, ...) cannot be supplied via
  environment variables, so this role renders `garage.toml` (template
  `garage.toml.j2`) onto the host bind-mount path before the container starts.
* The **secrets** (`rpc_secret`) are generated at runtime into a root-only file
  on the host and fed to Garage via `GARAGE_RPC_SECRET_FILE`. No secrets are
  stored in the repo and no ansible-vault is required.
* The cluster layout is auto-configured by launching the container with
  `garage server --single-node`, so no `garage layout assign/apply` is needed.
* The bucket and access key are provisioned **after** the container is running
  by the `provision` tasks, which are called automatically by `ansible_podman`
  at the end of its main task flow (same pattern as the borgmatic plugin). The
  resulting access key id + secret are written to `garage_credentials_file`
  (root, mode 0600) for the operator to copy into the client (e.g.
  CNPG/barman-cloud) configuration.

## Variables

See `defaults/main.yml`. Key ones:

| Variable | Default | Purpose |
|---|---|---|
| `garage_image` | `docker.io/dxflrs/garage:v2.4.1` | Container image |
| `garage_containername` | `garage0` | Container / systemd unit name |
| `garage_path_base` | `/mnt/cntr/unsynced/garage/0` | Config + metadata + secrets root |
| `garage_path_data` | `/mnt/backupdisk/garage_s3/data` | Object-block data dir (bulk disk) |
| `garage_s3_region` | `garage` | S3 region |
| `garage_bucket_name` | `cnpg-backup` | Bucket created by `provision` |
| `garage_key_name` | `cnpg-backup-key` | Access key created by `provision` |

## Usage

Register the plugin on the host:

```yaml
podman_container_plugin_garage:
  - "garage0"
```

Declare the `garage0` container (with `command: ["server", "--single-node"]`,
the `garage.toml`/meta/data/secrets volumes and `GARAGE_RPC_SECRET_FILE` env)
in `podman_containers`, then deploy via the existing podman playbook:

```bash
ansible-playbook playbooks/podman.yml -e '{"podman_limited_containers":["garage0","traefik0"]}'
```

The `ansible_podman` role runs the garage plugin (renders `garage.toml`,
generates the RPC secret) before creating the container, then calls the
`ansible_garage` provision tasks afterward to create the bucket and access key.

Because Garage's S3 API does not speak TLS, front it with a TLS-terminating
reverse proxy (Traefik is used elsewhere in this collection) serving a
CACert-issued certificate; the `garage0` container carries Traefik labels
routing `Host(<hostname>)` to its in-container port `3900`.
