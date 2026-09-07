#!/usr/bin/env bash
set -uo pipefail
cd /home/shiroyasha/vfio-acpi/build/AutoVirt/src/edk2-stable202605
export WORKSPACE="$(pwd)"
export EDK_TOOLS_PATH="$WORKSPACE/BaseTools"
export CONF_PATH="$WORKSPACE/Conf"
export PYTHON_COMMAND=/usr/bin/python3

echo "[*] Building BaseTools..."
make -C BaseTools -j"$(nproc)" || { echo "BASETOOLS FAILED"; exit 1; }

echo "[*] edksetup..."
set +u
source edksetup.sh || { echo "EDKSETUP FAILED"; exit 1; }
set -u

echo "[*] Building OVMF (RELEASE, SecureBoot + SMM + TPM)..."
build -p OvmfPkg/OvmfPkgX64.dsc -a X64 -t GCC -b RELEASE -n "$(nproc)" \
  -D SECURE_BOOT_ENABLE=TRUE -D SMM_REQUIRE=TRUE \
  -D TPM1_ENABLE=TRUE -D TPM2_ENABLE=TRUE || { echo "OVMF BUILD FAILED"; exit 1; }

echo "[*] Output:"
ls -la Build/OvmfX64/RELEASE_GCC/FV/OVMF_CODE.fd Build/OvmfX64/RELEASE_GCC/FV/OVMF_VARS.fd
echo "OVMF_BUILD_OK"
