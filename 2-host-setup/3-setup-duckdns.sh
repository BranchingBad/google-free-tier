#!/bin/bash
#
# Phase 3: Set up DuckDNS for dynamic IP updates.
#
# This script configures a cron job to automatically update a DuckDNS
# domain, which is useful when your VM's external IP address might change.

source "$(dirname "$0")/common.sh"

# --- Constants ---
#
# Using a variable for the install directory makes it easy to change.
# Using a hidden directory (.duckdns) is a common convention for config/data files.
INSTALL_DIR="${HOME}/.duckdns"
SCRIPT_FILE="${INSTALL_DIR}/update.sh"
LOG_FILE="${INSTALL_DIR}/duck.log"

# --- Function to prompt for user input ---
prompt_for_credentials() {
    # Prompt for Domain
    while [[ -z "${DOMAIN:-}" ]]; do
        read -p "Enter your DuckDNS Subdomain (e.g., 'myserver'): " DOMAIN
        if [[ -z "${DOMAIN}" ]]; then
            log_error "Domain cannot be empty."
        fi
    done
    
    # Prompt for Token (secretly)
    # The `-s` flag prevents the token from being displayed on screen.
    while [[ -z "${TOKEN:-}" ]]; do
        read -s -p "Enter your DuckDNS Token: " TOKEN
        echo "" # Add a newline after the prompt
        if [[ -z "${TOKEN}" ]]; then
            log_error "Token cannot be empty."
        fi
    done
}

# --- Main Logic ---
main() {
    log_info "--- Phase 3: Setting up DuckDNS ---"

    # Allow passing credentials as arguments for automation
    # ./setup_duckdns.sh [domain] [token]
    DOMAIN="${1:-}"
    TOKEN="${2:-}"

    if [[ -z "${DOMAIN}" || -z "${TOKEN}" ]]; then
        prompt_for_credentials
    else
        log_info "Using domain and token from script arguments."
    fi

    log_info "Creating installation directory at ${INSTALL_DIR}..."
    mkdir -p "${INSTALL_DIR}"

    log_info "Creating updater script: ${SCRIPT_FILE}"
    # Using a HEREDOC to create the script file.
    # This version is more robust:
    #   - It logs the date.
    #   - It doesn't use the insecure -k flag with curl.
    cat <<EOF > "${SCRIPT_FILE}"
#!/bin/bash
# Auto-generated DuckDNS update script
# Logs to: ${LOG_FILE}

# Get the directory of the script itself
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
LOG_FILE="\${DIR}/duck.log"

echo -n "\$(date): " >> "\${LOG_FILE}"
curl -s "https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=" >> "\${LOG_FILE}"
echo "" >> "\${LOG_FILE}"
EOF

    log_info "Setting script permissions..."
    chmod 700 "${SCRIPT_FILE}"

    log_info "Running initial test..."
    # We call the script directly to test it.
    "${SCRIPT_FILE}"

    # Check the latest log entry for "OK"
    if tail -n 1 "${LOG_FILE}" | grep -q "OK"; then
        log_success "DuckDNS update successful."

        log_info "Setting up cron job to run every 5 minutes..."
        # This is a safe way to add a cron job. It avoids creating duplicates.
        CRON_CMD="*/5 * * * * ${SCRIPT_FILE}"
        
        # 1. `crontab -l || true`: Get current crontab, or empty if none exists.
        # 2. `grep -vF "${SCRIPT_FILE}"`: Filter out any existing line for our script.
        # 3. `echo "${CRON_CMD}"`: Add our new cron command.
        # 4. `crontab -`: Load the result as the new crontab.
        (crontab -l 2>/dev/null | grep -vF "${SCRIPT_FILE}"; echo "${CRON_CMD}") | crontab -

        log_success "Cron job successfully configured."

    else
        log_error "DuckDNS update failed. Please check your settings."
        log_info "See the log for details: ${LOG_FILE}"
    fi

    log_info "-------------------------------------"
}

main "$@"
