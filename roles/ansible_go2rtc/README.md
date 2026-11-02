# imp1sh.ansible_managemynetwork.ansible_go2rtc

Container-only role: renders `go2rtc.yaml` onto host-side bind-mount paths for a
go2rtc container managed by the `ansible_podman` role.

No package installation, no service management, no container declaration.

## Usage

Enable the podman plugin for the container instance and point the role at the
host path that is bind-mounted into the container:

```yaml
podman_container_plugin_go2rtc:
  - "go2rtc0"

go2rtc_path_config: "/mnt/cntr/unsynced/go2rtc/0/config"
go2rtc_containername: "go2rtc0"      # enables restart-on-change

go2rtc_config:
  log:
    level: info
  api:
    listen: ":1984"
  rtsp:
    listen: ":8554"
  webrtc:
    listen: "[::]:8555"
    candidates:
      - 10.10.112.175:8555
    ice_servers: []
  streams:
    cam:
      - "exec:ffmpeg … -f rtsp {output}#killsignal=2#killtimeout=5"
```

`go2rtc_config` is dumped verbatim via `to_nice_yaml` (width widened to avoid
wrapping long `exec:` command strings).

## Variables

| Variable | Default | Description |
|---|---|---|
| `go2rtc_path_config` | `null` (required) | Host directory for the rendered config |
| `go2rtc_file_config` | `go2rtc.yaml` | Config filename |
| `go2rtc_owner` / `go2rtc_group` | `root` / `root` | File ownership |
| `go2rtc_mode_config` | `0644` | File mode |
| `go2rtc_config` | `{}` | go2rtc.yaml content as dict |
| `go2rtc_containername` | `null` | Container name for restart-on-change |

Container restart respects `podman_use_quadlet` (`<name>` vs `container-<name>`).
