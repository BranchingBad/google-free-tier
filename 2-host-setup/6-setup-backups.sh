#!/bin/bash
#
# Phase 6: Set up automated daily backups to Google Cloud Storage.

# Resolve the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# --- Constants ---
BACKUP_SCRIPT_PATH="/usr/local/bin/backup-to-gcs.sh"

# --- Main Logic ---
main() {
    log_info "--- Phase 6: Setting up Automated Backups ---"
    ensure_root

    # Support Env Vars or CLI Args
    local BUCKET_NAME="${1:-${GCS_BUCKET_NAME}}"
    local BACKUP_DIR="${2:-${BACKUP_DIR}}"

    # Validate
    if [[ -z "${BUCKET_NAME}" ]]; then
        log_error "Bucket name is empty. Usage: $0 <GCS_BUCKET_NAME> <BACKUP_DIRECTORY>"
        exit 1
    fi

    if [[ -z "${BACKUP_DIR}" || ! -d "${BACKUP_DIR}" ]]; then
        log_error "Directory '${BACKUP_DIR}' does not exist or was not specified."
        exit 1
    fi

    # ... (Rest of dependencies check and script generation)
    if ! command -v gsutil &> /dev/null; then
        log_warn "gsutil command not found. Installing Google Cloud SDK..."
        apt-get update -qq
        apt-get install -y -qq apt-transport-https ca-certificates gnupg
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        apt-get update -qq
        apt-get install -y -qq google-cloud-sdk
        log_success "Google Cloud SDK installed."
    fi

    log_info "Creating backup script at ${BACKUP_SCRIPT_PATH}..."
    
    cat <<EOF > "${BACKUP_SCRIPT_PATH}"
#!/bin/bash
# ... (Backup script content same as before) ...
set -euo pipefail
BUCKET_NAME="${BUCKET_NAME}"
BACKUP_DIR="${BACKUP_DIR}"
BACKUP_FILENAME="backup-\$(date -u +"%Y-%m-%d-%H%M%S").tar.gz"
TEMP_FILE="/tmp/\${BACKUP_FILENAME}"
DAYS_TO_KEEP=7

log() { echo "[\$(date -u +"%Y-%m-%dT%H:%M:%SZ")] \$1"; }

log "Creating archive of \${BACKUP_DIR}..."
tar -czf "\${TEMP_FILE}" -C "\$(dirname "\${BACKUP_DIR}")" "\$(basename "\${BACKUP_DIR}")"

log "Uploading \${BACKUP_FILENAME} to gs://\${BUCKET_NAME}..."
if ! gsutil cp "\${TEMP_FILE}" "gs://\${BUCKET_NAME}/"; then
    log "ERROR: Backup upload failed!"
    exit 1
fi

rm "\${TEMP_FILE}"

log "Cleaning up backups older than \${DAYS_TO_KEEP} days..."
gsutil ls -l "gs://\${BUCKET_NAME}" | while read -r _ timestamp _; do
    [[ \$REPLY != *"backup-"* ]] && continue
    file_date=\$(date -d "\${timestamp}" +%s)
    cutoff_date=\$(date -d "- \${DAYS_TO_KEEP} days" +%s)
    if (( file_date < cutoff_date )); then
        old_file_url=\$(echo "\$REPLY" | awk '{print \$3}')
        log "Deleting old backup: \${old_file_url}"
        gsutil rm "\${old_file_url}"
    fi
done
log "Backup complete."
EOF

    chmod 700 "${BACKUP_SCRIPT_PATH}"
    local cron_log="/var/log/backup.log"
    local cron_cmd="0 3 * * * ${BACKUP_SCRIPT_PATH} >> ${cron_log} 2>&1"
    (crontab -l 2>/dev/null | grep -vF "${BACKUP_SCRIPT_PATH}"; echo "${cron_cmd}") | crontab -

    log_success "Setup complete!"
}

main "$@"