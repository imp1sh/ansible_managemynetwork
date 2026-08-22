# imp1sh.ansible_managemynetwork.ansible_rpmfusion

Enables RPM Fusion repositories on Fedora and installs multimedia codecs (H.264, H.265, AAC, etc.), hardware-accelerated video decode drivers, and DVD playback support. Follows the official [RPM Fusion Configuration guide](https://rpmfusion.org/Configuration).

Fedora-only. Skips gracefully on non-Fedora hosts.

## What it does

| Step | Action |
|------|--------|
| **1. Repos** | Enables RPM Fusion free, nonfree, and optionally tainted repos via dnf |
| **2. ffmpeg swap** | Replaces Fedora's `ffmpeg-free` with RPM Fusion's full `ffmpeg` (H.264/H.265/AAC encode+decode) |
| **3. Multimedia** | Installs the `@multimedia` group — gstreamer plugins and complementary codecs |
| **4. HW accel** | Installs VA-API driver based on GPU vendor (Intel/AMD/NVIDIA) |
| **5. DVD** | Installs `libdvdcss` from free-tainted repo |
| **6. Firmware** | Installs non-free firmwares from nonfree-tainted repo |

Steps 2–6 are independently toggled by variables.

## Variables

### Repositories

| Variable | Default | Description |
|----------|---------|-------------|
| `rpmfusion_enable_free` | `true` | Enable RPM Fusion Free (OSS, redistributable) |
| `rpmfusion_enable_nonfree` | `true` | Enable RPM Fusion Nonfree (proprietary firmware/drivers) |
| `rpmfusion_enable_free_tainted` | `false` | Enable free-tainted (libdvdcss, FLOSS but legally restricted) |
| `rpmfusion_enable_nonfree_tainted` | `false` | Enable nonfree-tainted (firmware with unclear redistribution status) |

### Codecs & multimedia

| Variable | Default | Description |
|----------|---------|-------------|
| `rpmfusion_swap_ffmpeg` | `true` | Swap `ffmpeg-free` → full `ffmpeg` (H.264/H.265/AAC) |
| `rpmfusion_install_multimedia` | `true` | Install `@multimedia` group (gstreamer plugins) |

### Hardware acceleration

| Variable | Default | Description |
|----------|---------|-------------|
| `rpmfusion_hw_driver` | `""` | GPU driver: `intel-new`, `intel-old`, `amd`, `nvidia`, or `""` to skip |
| `rpmfusion_hw_driver_i686` | `false` | Also install i686 variant (Steam/Wine compat) |

Driver mapping:

| Value | Package | Notes |
|-------|---------|-------|
| `intel-new` | `intel-media-driver` | Broadwell+ (Gen 8+) |
| `intel-old` | `libva-intel-driver` | Pre-Broadwell |
| `amd` | `mesa-va-drivers-freeworld` | Fedora 37+, AMD GPUs |
| `nvidia` | `libva-nvidia-driver` | Bridges NVDEC/NVENC to VAAPI |

### DVD & firmware

| Variable | Default | Description |
|----------|---------|-------------|
| `rpmfusion_install_dvd` | `false` | Install `libdvdcss` (auto-enables free-tainted repo) |
| `rpmfusion_install_firmware` | `false` | Install non-free firmwares (auto-enables nonfree-tainted repo) |

## Usage

In `group_vars/os_desktop_fedora.yml`:

```yaml
rpmfusion_hw_driver: "intel-new"
rpmfusion_install_dvd: true
```

Or per-host in `host_vars`:

```yaml
rpmfusion_hw_driver: "amd"
rpmfusion_hw_driver_i686: true
```

## How tainted repos work

Setting `rpmfusion_install_dvd: true` automatically enables `rpmfusion_enable_free_tainted` — you don't need to set both. Same for `rpmfusion_install_firmware: true` and `rpmfusion_enable_nonfree_tainted`. If you want a tainted repo enabled without installing DVD/firmware, set the `*_tainted` variable directly.
