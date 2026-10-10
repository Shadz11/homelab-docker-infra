#!/usr/bin/env bash
# =============================================================================
# Private Cloud & Homelab State Backup + 14-Day Rolling Retention Script
# =============================================================================
# Compresses persistent homelab system state (Nextcloud private cloud metadata,
# databases, and service configurations) into timestamped .tar.gz archives and
# automatically rotates out snapshots older than 14 days so storage never fills.
#
# Cron Example (Runs nightly at 03:15 AM):
#   15 3 * * * /srv/homelab/scripts/backup-config.sh >> /var/log/homelab-backup.log 2>&1
# =============================================================================

set -euo pipefail

CONFIG_ROOT="${CONFIG_DIR:-/srv/homelab/config}"
BACKUP_ROOT="${BACKUP_DIR:-/srv/homelab/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
ARCHIVE_NAME="homelab-state-${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${BACKUP_ROOT}/${ARCHIVE_NAME}"

log_info() {
  printf "[%s] [INFO] %s\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$1"
}

log_error() {
  printf "[%s] [ERROR] %s\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$1" >&2
}

if [[ ! -d "${CONFIG_ROOT}" ]]; then
  log_error "Source state directory '${CONFIG_ROOT}' does not exist. Aborting backup."
  exit 1
fi

mkdir -p "${BACKUP_ROOT}"

log_info "Starting nightly private cloud & homelab state backup from '${CONFIG_ROOT}'..."
tar -czf "${ARCHIVE_PATH}" -C "$(dirname "${CONFIG_ROOT}")" "$(basename "${CONFIG_ROOT}")"

ARCHIVE_SIZE="$(du -h "${ARCHIVE_PATH}" | cut -f1)"
log_info "Compressed state archive created: ${ARCHIVE_PATH} (${ARCHIVE_SIZE})"

log_info "Rotating backup archives older than ${RETENTION_DAYS} days in '${BACKUP_ROOT}'..."
find "${BACKUP_ROOT}" -maxdepth 1 -type f -name "homelab-state-*.tar.gz" -mtime +"${RETENTION_DAYS}" -delete

log_info "Nightly disaster recovery backup and ${RETENTION_DAYS}-day retention rotation completed successfully."
