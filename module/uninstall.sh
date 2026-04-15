#!/system/bin/sh

for mnt in /mnt/media_rw/????-????; do
    if mount | grep -q "fuse.*$mnt"; then
        umount -l "$mnt" 2>/dev/null && rmdir "$mnt" 2>/dev/null
    fi
done

rm -f /data/local/tmp/exfat-module.log
