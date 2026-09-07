#!/usr/bin/env bash
# Add/remove a SEPARATE systemd-boot entry that disables the CPU mitigations
# which tax the VM-exit path on Zen 4 (SRSO Safe RET, TSA buffer clearing,
# spectre_v2 eIBRS/STIBP, VMSCAPE IBPB).
#
#   sudo ./root-step11-boot-entry.sh show     - list current entries + options
#   sudo ./root-step11-boot-entry.sh add      - create the test entry
#   sudo ./root-step11-boot-entry.sh remove   - delete the test entry
#
# Your existing entry is never modified. Pick the test entry at the boot menu;
# to go back, just boot the normal one. Nothing here is permanent.
set -uo pipefail
MODE=${1:-show}
ENTRIES=/boot/loader/entries
TESTNAME=cachyos-vmlatency
EXTRA="mitigations=off"

[ -d "$ENTRIES" ] || { echo "!! $ENTRIES not found"; exit 1; }

show() {
    echo "== entries in $ENTRIES =="
    for f in "$ENTRIES"/*.conf; do
        [ -e "$f" ] || continue
        echo "--- $(basename "$f")"
        sed -n 's/^\(title\|linux\|initrd\|options\)/  &/p' "$f"
    done
    echo
    echo "== systemd-boot default =="
    bootctl list 2>/dev/null | grep -A1 'title:' | head -20 || true
}

case "$MODE" in
  show) show ;;

  add)
    # pick the primary cachyos entry: not fallback, not our own test entry
    SRC=$(ls "$ENTRIES"/*.conf 2>/dev/null \
          | grep -iv fallback | grep -iv "$TESTNAME" \
          | xargs -r grep -il 'cachyos' | head -1)
    [ -n "$SRC" ] || SRC=$(ls "$ENTRIES"/*.conf | grep -iv fallback | head -1)
    [ -n "$SRC" ] || { echo "!! no source entry found"; exit 1; }
    echo "== source entry: $SRC =="
    cat "$SRC"

    DST="$ENTRIES/$TESTNAME.conf"
    cp "$SRC" "$DST"
    sed -i "s|^title.*|title   CachyOS (VM latency test - mitigations off)|" "$DST"
    if grep -q '^options' "$DST"; then
        sed -i "s|^options\(.*\)|options\1 $EXTRA|" "$DST"
    else
        echo "options $EXTRA" >> "$DST"
    fi
    # keep it from being auto-selected as default
    sed -i "/^sort-key/d" "$DST"
    echo "sort-key  zz-vmlatency" >> "$DST"

    echo
    echo "== created $DST =="
    cat "$DST"
    echo
    echo "Reboot and choose 'CachyOS (VM latency test - mitigations off)' at the menu."
    echo "Your normal entry is unchanged."
    ;;

  remove)
    if [ -f "$ENTRIES/$TESTNAME.conf" ]; then
        rm -f "$ENTRIES/$TESTNAME.conf"
        echo "== removed $ENTRIES/$TESTNAME.conf =="
    else
        echo "== nothing to remove =="
    fi
    ;;

  *) echo "usage: $0 [show|add|remove]"; exit 1 ;;
esac
