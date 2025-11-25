#!/bin/bash
#
# Common utilities and settings for shell scripts.
# This script is intended to be sourced, not executed directly.

# --- Strict Mode ---
#
# -e: exit immediately on non-zero exit status
# -u: treat unset variables as an error
# -o pipefail: if any command in a pipeline fails, the pipe's exit status is that command's
set -euo pipefail

# --- Log Formatting ---
#
# Provides color-coded and prefixed log messages.
#
# Usage:
#   log_info "This is an informational message."
#   log_success "Something succeeded."
#   log_warn "This is a warning."
#   log_error "This is an error."
#
# ---------------------------
_log_prefix() {
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [$1] "
}

log_info() {
    echo -e "$(_log_prefix "INFO") $1"
}

log_success() {
    echo -e "$(_log_prefix "✅") \033[0;32m$1\033[0m"
}

log_warn() {
    echo -e "$(_log_prefix "WARN") \033[0;33m$1\033[0m"
}

log_error() {
    echo -e "$(_log_prefix "❌") \033[0;31m$1\033[0m" >&2
}

# --- Root Check ---
#
# Ensures the script is being run as root. If not, it logs an error
# and exits.
#
# Usage:
#   ensure_root
# ---------------------------
ensure_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        log_error "This script must be run as root."
        log_info "👉 Try running: sudo bash ${0##*/}"
        exit 1
    fi
}
