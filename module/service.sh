#!/system/bin/sh

MODDIR="${0%/*}"
FUSE_BIN="$MODDIR/system/bin/mount.exfat-fuse"
LOG="/data/local/tmp/exfat-module.log"
MOUNTED_DEVS=""

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

wait_boot() {
    local tries=0
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 3
        tries=$((tries + 1))
        [ $tries -gt 60 ] && { log "ERROR: boot timeout"; exit 1; }
    done
    sleep 5
}

get_vol_id() {
    local dev="$1"
    local uuid
    uuid=$(blkid "$dev" 2>/dev/null | grep -oE 'UUID="[^"]+"' | cut -d'"' -f2)
    if [ -z "$uuid" ]; then
        echo "$(basename "$dev" | tr '[:lower:]' '[:upper:]')"
        return
    fi
    local clean="${uuid//-/}"
    local part1="${clean:0:4}"
    local part2="${clean:4:4}"
    echo "${part1^^}-${part2^^}"
}

is_exfat() {
    local dev="$1"
    blkid "$dev" 2>/dev/null | grep -qi 'TYPE="exfat"'
}

is_mounted() {
    local dev="$1"
    grep -q "^$dev " /proc/mounts 2>/dev/null
}

mount_exfat() {
    local dev="$1"

    echo "$MOUNTED_DEVS" | grep -qF "$dev" && return

    is_exfat "$dev" || return
    is_mounted "$dev" && { MOUNTED_DEVS="$MOUNTED_DEVS $dev"; return; }

    local vol_id
    vol_id=$(get_vol_id "$dev")
    local mnt_raw="/mnt/media_rw/$vol_id"

    log "Found exFAT: $dev -> $mnt_raw (ID: $vol_id)"

    mkdir -p "$mnt_raw" 2>/dev/null
    umount -f "$mnt_raw" 2>/dev/null || true
    umount -l "$mnt_raw" 2>/dev/null || true
    sleep 1

    "$FUSE_BIN" "$dev" "$mnt_raw" \
        -o noatime \
        -o uid=1023,gid=1023 \
        -o fmask=0007,dmask=0007 \
        -o allow_other \
        -o blksize=4096

    local ret=$?
    if [ $ret -eq 0 ]; then
        log "Mounted $dev at $mnt_raw"
        MOUNTED_DEVS="$MOUNTED_DEVS $dev"

        chown root:media_rw "$mnt_raw"
        chmod 770 "$mnt_raw"

        am broadcast \
            -a android.intent.action.MEDIA_MOUNTED \
            --ez read-only false \
            -d "file://$mnt_raw" \
            > /dev/null 2>&1 &
    else
        log "Failed to mount $dev (exit: $ret)"
        rmdir "$mnt_raw" 2>/dev/null || true
    fi
}

scan_devices() {
    for dev in /dev/block/mmcblk1p1 \
               /dev/block/mmcblk1 \
               /dev/block/mmcblk2p1 \
               /dev/block/mmcblk2; do
        [ -b "$dev" ] && mount_exfat "$dev"
    done
}

log "=== exFAT module service starting ==="
log "Module: $MODDIR"
log "Binary: $FUSE_BIN"

if [ ! -x "$FUSE_BIN" ]; then
    log "ERROR: mount.exfat-fuse not found or not executable"
    exit 1
fi

wait_boot
log "Boot completed — starting monitor loop"

scan_devices

while true; do
    scan_devices
    sleep 15
done
