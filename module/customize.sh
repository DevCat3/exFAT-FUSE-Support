#!/system/bin/sh

ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "   exFAT FUSE Support Module"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ui_print "Checking kernel FUSE support..."
if ! cat /proc/filesystems | grep -q "fuse"; then
    ui_print "FATAL: This kernel has no FUSE support."
    ui_print "Cannot install this module."
    abort
fi
ui_print "FUSE supported."

ui_print "Checking architecture..."
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    ui_print "FATAL: Only arm64 (aarch64) is supported."
    ui_print "Detected: $ARCH"
    abort
fi
ui_print "arm64 confirmed."

ui_print "Extracting files..."
unzip -o "$ZIPFILE" \
    'module.prop' \
    'service.sh' \
    'uninstall.sh' \
    'system/*' \
    -d "$MODPATH" >&2

ui_print "Setting permissions..."
set_perm_recursive "$MODPATH/system/bin" root root 0755 0755

for bin in \
    mount.exfat-fuse \
    mount.exfat \
    mkfs.exfat \
    fsck.exfat \
    exfatlabel \
    dumpexfat; do
    BIN="$MODPATH/system/bin/$bin"
    [ -f "$BIN" ] && set_perm "$BIN" root root 0755
done

set_perm "$MODPATH/service.sh"   root root 0755
set_perm "$MODPATH/uninstall.sh" root root 0755

ui_print ""
ui_print "Installation complete."
ui_print "Binaries installed to /system/bin/"
ui_print "Service will auto-mount exFAT cards on boot."
ui_print ""
ui_print "Reboot your device to activate."
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
