#!/usr/bin/bash
##
## rebuild_Win2025_iso.sh
## =========================
## This script is to be executed on the Proxmox host prior to running the packer build.
## It will rebuild the Windows Server 2025 ISO with a custom autounattend.xml file.
## Usage:
##   ./rebuild_Win2025_iso.sh [options]
##
## Options (position-independent):
##   --original-iso-name VALUE
##   --modified-iso-name VALUE
##   --storage VALUE
##   --autounattend-file VALUE
##   -h | --help
##
## Backward compatibility:
##   Positional arguments are still accepted in this order:
##   [original_iso_name] [modified_iso_name] [proxmox_storage_name] [autounattend.xml_file_full_path]

set -euo pipefail

O_ISO="WIN2025-SERVER_en_us.iso"
M_ISO="WIN2025-SERVER_Moded_unattended.iso"
STORAGE="local"
autoFile="autounattend.xml"

usage() {
    cat << 'EOF'
Usage: ./rebuild_Win2025_iso.sh [options]

Options:
    --original-iso-name VALUE    Original/source Windows ISO filename
    --modified-iso-name VALUE    Output modified Windows ISO filename
    --storage VALUE              Proxmox storage name where ISO files exist
    --autounattend-file VALUE    Full path to autounattend.xml file
    -h, --help                   Show this help

Examples:
    ./rebuild_Win2025_iso.sh --storage ntfs2tb-iso --original-iso-name Win2025-SERVER_EVAL_x64FRE_en-us.iso --modified-iso-name Win2025-SERVER_Moded_Unattended.iso --autounattend-file /tmp/autounattend.xml
    ./rebuild_Win2025_iso.sh --storage=ntfs2tb-iso --autounattend-file=/tmp/autounattend.xml

Positional fallback (legacy):
    ./rebuild_Win2025_iso.sh ORIGINAL_ISO MODIFIED_ISO STORAGE AUTOUNATTEND_FILE
EOF
}

require_value() {
    local flag="$1"
    local value="${2:-}"
    if [[ -z "$value" || "$value" == --* ]]; then
        echo "Missing value for ${flag}"
        usage
        exit 1
    fi
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --original-iso-name)
            require_value "$1" "${2:-}"
            O_ISO="$2"
            shift 2
            ;;
        --original-iso-name=*)
            O_ISO="${1#*=}"
            shift
            ;;
        --modified-iso-name)
            require_value "$1" "${2:-}"
            M_ISO="$2"
            shift 2
            ;;
        --modified-iso-name=*)
            M_ISO="${1#*=}"
            shift
            ;;
        --storage)
            require_value "$1" "${2:-}"
            STORAGE="$2"
            shift 2
            ;;
        --storage=*)
            STORAGE="${1#*=}"
            shift
            ;;
        --autounattend-file)
            require_value "$1" "${2:-}"
            autoFile="$2"
            shift 2
            ;;
        --autounattend-file=*)
            autoFile="${1#*=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do
                POSITIONAL+=("$1")
                shift
            done
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

# Legacy positional fallback if any positional args are provided.
if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
    if [[ ${#POSITIONAL[@]} -gt 4 ]]; then
        echo "Too many positional arguments: ${#POSITIONAL[@]} (max 4)."
        usage
        exit 1
    fi
    [[ ${#POSITIONAL[@]} -ge 1 ]] && O_ISO="${POSITIONAL[0]}"
    [[ ${#POSITIONAL[@]} -ge 2 ]] && M_ISO="${POSITIONAL[1]}"
    [[ ${#POSITIONAL[@]} -ge 3 ]] && STORAGE="${POSITIONAL[2]}"
    [[ ${#POSITIONAL[@]} -ge 4 ]] && autoFile="${POSITIONAL[3]}"
fi

get_storage_path() {
    local storage_name="$1"
    local storage_type
    local pool
    local vg
    storage_type=$(awk -v s="$storage_name" '$2 == s {print $1; exit}' /etc/pve/storage.cfg | tr -d ':')

    case "$storage_type" in
    dir|nfs|cifs)
        # Pulls the absolute file directory path
                awk -v s="$storage_name" '$1 ~ /^(dir|nfs|cifs):$/ && $2 == s {f=1; next} f && $1 == "path" {print $2; exit} f && /^[^ \t]/ {exit}' /etc/pve/storage.cfg
        ;;
    zfspool)
        # Pulls the ZFS pool name (e.g. rpool/data)
                pool=$(awk -v s="$storage_name" '$1 == "zfspool:" && $2 == s {f=1; next} f && $1 == "pool" {print $2; exit} f && /^[^ \t]/ {exit}' /etc/pve/storage.cfg)
                zfs get -H -o value mountpoint "$pool"
        ;;
    lvm|lvmthin)
        # Pulls the LVM Volume Group / Dev path
                vg=$(awk -v s="$storage_name" '$1 ~ /^lvm/ && $2 == s {f=1; next} f && $1 == "vgname" {print $2; exit} f && /^[^ \t]/ {exit}' /etc/pve/storage.cfg)
                echo "/dev/$vg"
        ;;
    *)
                echo "Proxmox_Storage_'$storage_type'_not_mapped_ERROR"
        ;;
  esac
}

storage_path="$(get_storage_path "$STORAGE")"
original_iso="${storage_path}/template/iso/${O_ISO}"
modified_iso="${storage_path}/template/iso/${M_ISO}"
echo "Original ISO Full Path =  $original_iso"
echo "Moded ISO Full Path = $modified_iso"

if [ ! -f "$original_iso" ]; then
    echo "Original ISO not found: $original_iso"
    exit 1
fi

# Clean previous output
if [ -f "$modified_iso" ]; then
    echo "Removing existing modified ISO: $modified_iso"
    rm -f "$modified_iso"
fi

# Extract ISO contents
mkdir -p iso_extract
#xorriso -osirrox on -indev $original_iso -extract / iso_extract
7z x "$original_iso" -oiso_extract

# Copy your custom file(s)
cp "$autoFile" iso_extract/

# Rebuild ISO with xorriso
#xorriso -as mkisofs -iso-level 3 -volid 'WIN2025' -eltorito-alt-boot -e boot/etfsboot.com -no-emul-boot -eltorito-alt-boot -e efi/microsoft/boot/efisys.bin -no-emul-boot -o $modified_iso iso_extract
#xorriso -as mkisofs \
#  -iso-level 3 \
#  -volid "WIN2025" \
#  -eltorito-boot boot/bootfix.bin \
#  -no-emul-boot \
#  -boot-load-size 8 \
#  -boot-info-table \
#  -eltorito-alt-boot \
#  -e efi/microsoft/boot/efisys.bin \
#  -no-emul-boot \
#  -o "$modified_iso" \
#  iso_extract

xorriso -as mkisofs \
  -iso-level 3 \
  -volid "WIN2025" \
  -eltorito-boot efi/microsoft/boot/cdboot.efi \
  -no-emul-boot \
  -boot-load-size 8 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e efi/microsoft/boot/efisys.bin \
  -no-emul-boot \
  -o "$modified_iso" \
  iso_extract

# Cleanup
rm -rf iso_extract
