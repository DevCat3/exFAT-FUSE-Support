# exFAT FUSE Support — KernelSU / Magisk Module

Adds exFAT filesystem support to Android devices via FUSE userspace driver.
Targets GSI/AOSP ROMs where the vendor exFAT kernel driver is missing or broken.

---

## Requirements

| Requirement | Details |
|---|---|
| Architecture | arm64 (aarch64) only |
| Android | 8.0+ (API 26+) |
| Root | KernelSU or Magisk |
| Kernel | Must have `CONFIG_FUSE` enabled |

---

## Installation

1. Download the latest `exfat-module-vX.X.X-arm64.zip` from [Releases](../../releases)
2. Open **KernelSU** or **Magisk Manager**
3. Tap **Install from storage** and select the zip
4. Reboot

After reboot, insert your exFAT SD card. It will be auto-mounted at `/mnt/media_rw/<LABEL>`.

---

## How It Works

The module ships static arm64 binaries cross-compiled from:
- [relan/exfat](https://github.com/relan/exfat) v1.4.0 — FUSE-based exFAT driver
- [libfuse](https://github.com/libfuse/libfuse) 2.9.9 — FUSE userspace library (static)

On boot, `service.sh` waits for `sys.boot_completed`, then polls `/dev/block/mmcblk*` every 15 seconds. When it detects an exFAT partition (via `blkid`), it mounts it using `mount.exfat-fuse` with media-friendly permissions (`uid/gid=1023`, `media_rw` group).

After a successful mount, it broadcasts `android.intent.action.MEDIA_MOUNTED` so the Android media scanner picks up the card.

---

## Installed Binaries

| Binary | Purpose |
|---|---|
| `mount.exfat-fuse` | Mount exFAT partitions via FUSE |
| `mkfs.exfat` | Format a partition as exFAT |
| `fsck.exfat` | Check and repair exFAT partitions |
| `exfatlabel` | Read/set volume label |
| `dumpexfat` | Dump exFAT filesystem info |

All binaries are installed to `/system/bin/`.

---

## Manual Mount

```sh
# Mount manually
mount.exfat-fuse /dev/block/mmcblk1p1 /mnt/media_rw/MY_CARD \
    -o uid=1023,gid=1023,fmask=0007,dmask=0007,allow_other

# Format SD card as exFAT
mkfs.exfat -n MY_CARD /dev/block/mmcblk1p1

# Check filesystem
fsck.exfat /dev/block/mmcblk1p1
```

---

## Logs

Service logs are written to `/data/local/tmp/exfat-module.log`:

```sh
adb shell cat /data/local/tmp/exfat-module.log
```

---

## Build from Source

The module is built automatically via GitHub Actions on every tag push.

### Trigger a build manually

1. Go to **Actions → Build exFAT & Package Module**
2. Click **Run workflow**
3. Enter a version tag (e.g. `v1.0.1`)

### What the workflow does

| Step | Action |
|---|---|
| NDK setup | Downloads Android NDK r26d |
| exFAT source | Downloads relan/exfat v1.4.0 |
| libfuse build | Cross-compiles libfuse 2.9.9 static for arm64 |
| exFAT build | Cross-compiles exfat-utils against static libfuse |
| Strip | Strips debug symbols from binaries |
| Package | Assembles Magisk/KernelSU module zip |
| Release | Publishes zip + binaries to GitHub Releases |

### Local build requirements

```
autoconf automake libtool pkg-config gettext curl unzip zip
Android NDK r26d
```

---

## Uninstall

- Uninstall from **KernelSU / Magisk Manager** and reboot.
- The uninstall script will unmount any active exFAT mounts and clean up the log file.

---

## License

- `exfat-utils`: GPL-2.0 — [relan/exfat](https://github.com/relan/exfat)
- `libfuse`: LGPL-2.1 — [libfuse/libfuse](https://github.com/libfuse/libfuse)
- Module scripts: MIT
