#!/bin/bash
## run_packer_build.sh
## =========================
## This script runs the Packer build for Proxmox KVM Windows Server 2025.
## Usage:
##   ./run_packer_build.sh [options]
##
## Example:
##   ./run_packer_build.sh \
##     --proxmox-host 192.168.0.18 \
##     --proxmox-os-user root \
##     --moded-iso-name Win2025-SERVER_Moded_Unattended.iso \
##     --orig-iso-name Win2025-SERVER_EVAL_x64FRE_en-us.iso \
##     --win-image-name 'Windows Server 2025 SERVERDATACENTER' \
##     --windows-time-zone America/Toronto \
##     --proxmox-storage-iso ntfs2tb-iso \
##     --administrator-password 'CHANGE_ME' \
##     --winrm-port 5986
##
## Assumptions:
## 1. Packer is installed on the local machine.
## 2. Jinja2-cli is installed on the local machine for template rendering.
## 3. SSH access to the Proxmox host is configured and working, with the provided user having sufficient permissions to execute commands and transfer files.
## 4. SSH keys are set up for passwordless authentication, or the user will be prompted for a password during execution.
## 5. The Proxmox host has the necessary tools (particularly: p7zip-full and xorriso) installed to rebuild the ISO.

set -euo pipefail

PROXMOX_HOST="192.168.0.18"
PROXMOX_OS_USER="root"
WIN2025_MODED_ISONAME="WIN2025-SERVER_Moded_Unattended.iso"
WIN2025_ORIG_ISONAME="Win2025-SERVER_EVAL_x64FRE_en-us.iso"
WIN2025_IMAGE_NAME="Windows Server 2025 SERVERDATACENTER"
WINDOWS_TIME_ZONE="America/Toronto"
PROXMOX_STORAGE_ISO="local"
ADMINISTRATOR_PASSWORD="P@ssw0rd!"
WINRM_PORT="5986"

usage() {
  cat << 'EOF'
Usage: ./run_packer_build.sh [options]

Options (position-independent):
  --proxmox-host VALUE              Proxmox host/IP (without protocol/port)
  --proxmox-os-user VALUE           SSH user on Proxmox host
  --moded-iso-name VALUE            Target modified Win2025 ISO name
  --orig-iso-name VALUE             Source/original Win2025 ISO name
  --win-image-name VALUE            Windows image name from install.wim
  --windows-time-zone VALUE         Windows time zone for autounattend
  --proxmox-storage-iso VALUE       Proxmox ISO storage name
  --administrator-password VALUE    Administrator password for autounattend
  --winrm-port VALUE                WinRM port
  -h, --help                        Show this help

You can pass options in any order.
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxmox-host)
      require_value "$1" "${2:-}"
      PROXMOX_HOST="$2"
      shift 2
      ;;
    --proxmox-host=*)
      PROXMOX_HOST="${1#*=}"
      shift
      ;;
    --proxmox-os-user)
      require_value "$1" "${2:-}"
      PROXMOX_OS_USER="$2"
      shift 2
      ;;
    --proxmox-os-user=*)
      PROXMOX_OS_USER="${1#*=}"
      shift
      ;;
    --moded-iso-name)
      require_value "$1" "${2:-}"
      WIN2025_MODED_ISONAME="$2"
      shift 2
      ;;
    --moded-iso-name=*)
      WIN2025_MODED_ISONAME="${1#*=}"
      shift
      ;;
    --orig-iso-name)
      require_value "$1" "${2:-}"
      WIN2025_ORIG_ISONAME="$2"
      shift 2
      ;;
    --orig-iso-name=*)
      WIN2025_ORIG_ISONAME="${1#*=}"
      shift
      ;;
    --win-image-name)
      require_value "$1" "${2:-}"
      WIN2025_IMAGE_NAME="$2"
      shift 2
      ;;
    --win-image-name=*)
      WIN2025_IMAGE_NAME="${1#*=}"
      shift
      ;;
    --windows-time-zone)
      require_value "$1" "${2:-}"
      WINDOWS_TIME_ZONE="$2"
      shift 2
      ;;
    --windows-time-zone=*)
      WINDOWS_TIME_ZONE="${1#*=}"
      shift
      ;;
    --proxmox-storage-iso)
      require_value "$1" "${2:-}"
      PROXMOX_STORAGE_ISO="$2"
      shift 2
      ;;
    --proxmox-storage-iso=*)
      PROXMOX_STORAGE_ISO="${1#*=}"
      shift
      ;;
    --administrator-password)
      require_value "$1" "${2:-}"
      ADMINISTRATOR_PASSWORD="$2"
      shift 2
      ;;
    --administrator-password=*)
      ADMINISTRATOR_PASSWORD="${1#*=}"
      shift
      ;;
    --winrm-port)
      require_value "$1" "${2:-}"
      WINRM_PORT="$2"
      shift 2
      ;;
    --winrm-port=*)
      WINRM_PORT="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

OnError() {
  local ERR=$?
  echo "Error occurred in script at line: ${BASH_LINENO[0]}. Exiting."
  exit $ERR
}
trap 'OnError' ERR

echo "**> Running Packer build for Proxmox KVM Windows Server 2025 ..."
echo "****> Starting packer init..."
/usr/bin/packer init .
echo "****< Packer init completed."
echo "****> Starting packer validate..."
/usr/bin/packer validate -var-file=./vars/winserver2025.auto.pkrvars.hcl .
echo "****< Packer validate completed."
echo "****> Starting ISO rebuild..."
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ./scripts/rebuild_Win2025_iso.sh ${PROXMOX_OS_USER}@${PROXMOX_HOST}:/tmp/rebuild_Win2025_iso.sh
#jinja2 http/Autounattend.xml.pkrtpl -D image_name='${WIN2025_IMAGE_NAME}' -D time_zone=${WINDOWS_TIME_ZONE} -D administrator_password=${ADMINISTRATOR_PASSWORD} -D winrm_port=${WINRM_PORT} > /tmp/autounattend.xml
export image_name=${WIN2025_IMAGE_NAME}
export time_zone=${WINDOWS_TIME_ZONE}
export administrator_password=${ADMINISTRATOR_PASSWORD}
export winrm_port=${WINRM_PORT}
envsubst < http/Autounattend.xml.pkrtpl > /tmp/autounattend.xml
unset image_name time_zone administrator_password winrm_port
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /tmp/autounattend.xml ${PROXMOX_OS_USER}@${PROXMOX_HOST}:/tmp/autounattend.xml
rm -f /tmp/autounattend.xml
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${PROXMOX_OS_USER}@${PROXMOX_HOST} "bash /tmp/rebuild_Win2025_iso.sh ${WIN2025_ORIG_ISONAME} ${WIN2025_MODED_ISONAME} ${PROXMOX_STORAGE_ISO} /tmp/autounattend.xml"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${PROXMOX_OS_USER}@${PROXMOX_HOST} "rm -f /tmp/rebuild_Win2025_iso.sh /tmp/autounattend.xml"
echo "****< ISO rebuild completed."
echo "****> Starting packer build..."
/usr/bin/packer build -force -var-file=./vars/winserver2025.auto.pkrvars.hcl .
echo "****< Packer build step completed."
echo "**< Packer build for Proxmox KVM Windows Server 2025 completed."
