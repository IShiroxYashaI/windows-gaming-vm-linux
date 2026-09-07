# Shared kernel-version derivation.  Sourced by kern-prep.sh, kern-build-kvm.sh
# and regen-patch.sh -- not executable on its own.
#
# Everything version-dependent is derived from the RUNNING kernel, so after a
# kernel update the build scripts run unedited.  To build against a kernel that
# is not the running one:
#
#     KREL=7.3.0-1-cachyos ./kern-prep.sh
#
# Note that a module built for a non-running kernel cannot be insmod'd until you
# are booted into it -- vermagic must match exactly.

KREL=${KREL:-$(uname -r)}

# 7.2.2-1-cachyos  ->  KBASE=7.2.2  KPKGREL=-1  KPKGNAME=-cachyos
KBASE=$(printf '%s' "$KREL" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' || true)
[ -n "$KBASE" ] || { echo "!! kver: no X.Y.Z version in '$KREL'"; exit 1; }
KREST=${KREL#"$KBASE"}
KPKGREL=$(printf '%s' "$KREST" | grep -oE '^-[0-9]+' || true)
[ -n "$KPKGREL" ] || { echo "!! kver: no -<pkgrel> in '$KREST'"; exit 1; }
KPKGNAME=${KREST#"$KPKGREL"}
[ -n "$KPKGNAME" ] || { echo "!! kver: no -<pkgname> in '$KREST'"; exit 1; }

# The CachyOS release tag, the tarball and the extracted directory all share
# this name, e.g. cachyos-7.2.2-1
KTAG="cachyos-${KBASE}${KPKGREL}"

# Repo root = wherever this file lives, so a clone to a different path works.
KBUILD_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

KBT=/usr/lib/modules/$KREL/build          # distro build tree (headers + Module.symvers)
KROOT=$KBUILD_ROOT/cachy
KSRC=$KROOT/$KTAG                         # extracted source tree
KTAR=$KROOT/$KTAG.tar.gz                  # source tarball
KURL=https://github.com/CachyOS/linux/releases/download/$KTAG/$KTAG.tar.gz

# The vermagic the build will produce, reconstructed from the parts above. If
# this does not equal the running kernel, the resulting modules cannot load.
KVERMAGIC="${KBASE}${KPKGREL}${KPKGNAME}"

kver_show() {
    echo "== kernel version =="
    printf '   running   %s\n' "$KREL"
    printf '   tag       %s\n' "$KTAG"
    printf '   source    %s\n' "$KSRC"
    printf '   build tree %s\n' "$KBT"
    if [ "$KVERMAGIC" != "$KREL" ]; then
        echo "   !! reconstructed vermagic '$KVERMAGIC' != running '$KREL'"
        echo "   !! the built modules would be rejected by insmod"
        exit 1
    fi
}
