#!/usr/bin/env bash
#
# Script to track package updates for release notes
# This script compares current package versions with previous versions and generates a report
# Improved with enhanced error handling, logging, and configurable options

# Exit on error if error handling is not explicitly defined
set -e

# Default configuration options (can be overridden by config file)
CONFIG_FILE="/etc/package_tracking/config.conf"
LOG_FILE="/var/log/package_tracking.log"
LOG_LEVEL="INFO"  # Options: DEBUG, INFO, WARNING, ERROR
DATA_DIR="/tmp/package-versions"
REPOS="core extra community multilib"
CHECK_INTERVAL=86400  # 24 hours in seconds
NOTIFY="true"
TIMEOUT=30  # Connection timeout in seconds
RETRY_COUNT=3  # Number of retries for network operations

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Files for storing package version data
CURRENT_VERSIONS_FILE="${DATA_DIR}/current_versions.txt"
PREVIOUS_VERSIONS_FILE="${DATA_DIR}/previous_versions.txt"
UPDATES_FILE="${DATA_DIR}/package_updates.md"
LAST_RUN_FILE="${DATA_DIR}/last_run.timestamp"

# Create directory for storing log files if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Create data directory if it doesn't exist
mkdir -p "${DATA_DIR}" 2>/dev/null || true

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    log "INFO" "Configuration loaded from $CONFIG_FILE"
else
    log "WARNING" "Configuration file not found at $CONFIG_FILE, using defaults"
    # Create default config directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
fi

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log "ERROR" "$1 is required but not installed."
        return 1
    fi
    return 0
}

# Function to check network connectivity
check_connection() {
    local attempt=1
    local max_attempts=$RETRY_COUNT
    local target="archlinux.org"
    
    while [ $attempt -le $max_attempts ]; do
        log "DEBUG" "Connection check attempt $attempt of $max_attempts"
        
        if ping -c 1 -W 5 "$target" &> /dev/null; then
            log "DEBUG" "Network connection to $target successful"
            return 0
        else
            log "WARNING" "Network connection attempt $attempt failed, retrying in 5 seconds"
            sleep 5
            attempt=$((attempt + 1))
        fi
    done
    
    log "ERROR" "Cannot connect to $target after $max_attempts attempts. Check your internet connection."
    return 1
}

# Logging function with log levels
log() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Only log if level is appropriate based on LOG_LEVEL setting
    case $LOG_LEVEL in
        DEBUG)
            ;;
        INFO)
            if [ "$level" = "DEBUG" ]; then return; fi
            ;;
        WARNING)
            if [ "$level" = "DEBUG" ] || [ "$level" = "INFO" ]; then return; fi
            ;;
        ERROR)
            if [ "$level" != "ERROR" ]; then return; fi
            ;;
    esac
    
    # Format the log message
    local formatted_msg="[$timestamp] $level: $message"
    
    # Output to console with color
    case $level in
        DEBUG)
            echo -e "${CYAN}$formatted_msg${NC}" >&2
            ;;
        INFO)
            echo -e "${GREEN}$formatted_msg${NC}" >&2
            ;;
        WARNING)
            echo -e "${YELLOW}$formatted_msg${NC}" >&2
            ;;
        ERROR)
            echo -e "${RED}$formatted_msg${NC}" >&2
            ;;
        *)
            echo -e "$formatted_msg" >&2
            ;;
    esac
    
    # Log to file
    echo "$formatted_msg" >> "$LOG_FILE"
}

# Function to clean up on exit
cleanup() {
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Script execution failed with exit code $exit_code"
    fi
    log "DEBUG" "Cleanup: removing temporary files"
    rm -f "${CURRENT_VERSIONS_FILE}.tmp" 2>/dev/null || true
    log "INFO" "Script execution completed with status code $exit_code"
    exit $exit_code
}

# Register the cleanup function to run on script exit
trap cleanup EXIT

# Function to get current package versions with improved error handling
get_current_versions() {
    log "INFO" "Getting current package versions..."
    
    # Make sure we have the necessary commands
    check_command "pacman" || return 1
    
    # Check network connection before proceeding
    if ! check_connection; then
        log "ERROR" "Network error: Package tracking aborted."
        return 1
    fi
    
    # Make sure we're using an updated database
    log "DEBUG" "Refreshing package database"
    if ! timeout "$TIMEOUT" pacman -Sy --noconfirm > /dev/null 2>&1; then
        log "ERROR" "Failed to update package database. Check your internet connection or Arch mirrors."
        return 1
    fi
    
    # Get package list from packages.x86_64
    if [ -f "packages.x86_64" ]; then
        local total_packages=0
        local processed_packages=0
        local failed_packages=0
        
        # Count total non-empty, non-comment lines
        total_packages=$(grep -v '^#\|^$' "packages.x86_64" | wc -l)
        log "DEBUG" "Found $total_packages packages to process"
        
        > "${CURRENT_VERSIONS_FILE}.tmp" # Create or truncate the temporary file
        
        while IFS= read -r pkg; do
            # Skip empty lines and comments
            [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
            
            processed_packages=$((processed_packages + 1))
            
            # Show progress every 10 packages
            if ((processed_packages % 10 == 0)); then
                log "DEBUG" "Processing package $processed_packages of $total_packages"
            fi
            
            # Get version information for each package with timeout and retry
            local attempt=1
            local success=false
            local version=""
            
            while [ $attempt -le $RETRY_COUNT ] && [ "$success" = false ]; do
                version=$(timeout "$TIMEOUT" pacman -Si "$pkg" 2>/dev/null | grep "Version" | head -n 1 | awk '{print $3}')
                
                if [ -n "$version" ]; then
                    success=true
                    echo "$pkg=$version" >> "${CURRENT_VERSIONS_FILE}.tmp"
                    log "DEBUG" "Got version for package $pkg: $version"
                else
                    log "WARNING" "Attempt $attempt: Could not get version for package: $pkg. Retrying..."
                    attempt=$((attempt + 1))
                    sleep 1
                fi
            done
            
            if [ "$success" = false ]; then
                failed_packages=$((failed_packages + 1))
                log "ERROR" "Failed to get version for package: $pkg after $RETRY_COUNT attempts"
            fi
        done < "packages.x86_64"
        
        # Sort the file for easier comparison
        if [ -f "${CURRENT_VERSIONS_FILE}.tmp" ]; then
            sort "${CURRENT_VERSIONS_FILE}.tmp" > "${CURRENT_VERSIONS_FILE}"
            rm "${CURRENT_VERSIONS_FILE}.tmp"
            log "INFO" "Processed $processed_packages packages, $failed_packages failed"
            log "INFO" "Current package versions saved to ${CURRENT_VERSIONS_FILE}"
        else
            log "ERROR" "Failed to create package version file"
            return 1
        fi
    else
        log "ERROR" "packages.x86_64 file not found!"
        return 1
    fi
    
    # Update the last run timestamp
    date +%s > "$LAST_RUN_FILE"
    
    return 0
}

# Function to save current versions as the new previous versions
save_versions_as_previous() {
    if [ -f "${CURRENT_VERSIONS_FILE}" ]; then
        cp "${CURRENT_VERSIONS_FILE}" "${PREVIOUS_VERSIONS_FILE}"
        log "INFO" "Saved current versions as previous for next comparison."
    else
        log "WARNING" "No current versions file found to save as previous."
        return 1
    fi
    return 0
}

# Function to compare current with previous versions
compare_versions() {
    log "INFO" "Comparing current package versions with previous versions..."
    
    # If previous versions file doesn't exist, create an empty one
    if [ ! -f "${PREVIOUS_VERSIONS_FILE}" ]; then
        log "WARNING" "No previous versions file found. This might be the first run."
        touch "${PREVIOUS_VERSIONS_FILE}"
    fi
    
    # Check if the current versions file exists
    if [ ! -f "${CURRENT_VERSIONS_FILE}" ]; then
        log "ERROR" "Current versions file doesn't exist. Run get_current_versions first."
        return 1
    fi
    
    # Create updates file with header
    echo "## 📦 Package Updates" > "${UPDATES_FILE}"
    echo "" >> "${UPDATES_FILE}"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')" >> "${UPDATES_FILE}"
    echo "" >> "${UPDATES_FILE}"
    
    # Track if we found any updates
    local found_updates=false
    local new_count=0
    local updated_count=0
    local removed_count=0
    
    while IFS='=' read -r pkg current_version; do
        # Skip empty lines
        [[ -z "$pkg" ]] && continue
        
        # Get previous version of this package
        local previous_version
        previous_version=$(grep "^${pkg}=" "${PREVIOUS_VERSIONS_FILE}" | cut -d'=' -f2)
        
        # If package is new or has a different version
        if [ -z "$previous_version" ]; then
            echo "- ➕ New package: **${pkg}** (${current_version})" >> "${UPDATES_FILE}"
            found_updates=true
            new_count=$((new_count + 1))
        elif [ "$previous_version" != "$current_version" ]; then
            echo "- 🔄 Updated: **${pkg}** (${previous_version} → ${current_version})" >> "${UPDATES_FILE}"
            found_updates=true
            updated_count=$((updated_count + 1))
        fi
    done < "${CURRENT_VERSIONS_FILE}"
    
    # Check for packages that were removed
    while IFS='=' read -r pkg previous_version; do
        # Skip empty lines
        [[ -z "$pkg" ]] && continue
        
        if ! grep -q "^${pkg}=" "${CURRENT_VERSIONS_FILE}"; then
            echo "- ❌ Removed: **${pkg}** (was ${previous_version})" >> "${UPDATES_FILE}"
            found_updates=true
            removed_count=$((removed_count + 1))
        fi
    done < "${PREVIOUS_VERSIONS_FILE}"
    
    # Add a summary of changes
    echo "" >> "${UPDATES_FILE}"
    echo "### Summary" >> "${UPDATES_FILE}"
    echo "- New packages: $new_count" >> "${UPDATES_FILE}"
    echo "- Updated packages: $updated_count" >> "${UPDATES_FILE}"
    echo "- Removed packages: $removed_count" >> "${UPDATES_FILE}"
    echo "" >> "${UPDATES_FILE}"
    
    # If no updates were found, add a note
    if [ "$found_updates" = false ]; then
        echo "No package updates since the previous release." >> "${UPDATES_FILE}"
    fi
    
    log "INFO" "Package comparison complete. Results written to ${UPDATES_FILE}"
    log "INFO" "Summary: $new_count new, $updated_count updated, $removed_count removed packages"
    
    return 0
}

# Function to check if an update should be performed based on the configured interval
should_update() {
    # If the last run file doesn't exist, we should update
    if [ ! -f "$LAST_RUN_FILE" ]; then
        log "DEBUG" "No last run timestamp found, update needed"
        return 0
    fi
    
    # Get the last run timestamp
    local last_run
    last_run=$(cat "$LAST_RUN_FILE")
    
    # Get current timestamp
    local now
    now=$(date +%s)
    
    # Calculate time difference
    local diff=$((now - last_run))
    
    # Log time since last run
    local hours=$((diff / 3600))
    local minutes=$(((diff % 3600) / 60))
    log "DEBUG" "Last run was $hours hours and $minutes minutes ago"
    
    # Check if enough time has passed since the last run
    if [ "$diff" -ge "$CHECK_INTERVAL" ]; then
        log "DEBUG" "Update interval exceeded ($CHECK_INTERVAL seconds), update needed"
        return 0
    else
        log "DEBUG" "Update interval not exceeded yet, no update needed"
        return 1
    fi
}

# Function to save the current configuration to the config file
save_config() {
    log "DEBUG" "Saving configuration to $CONFIG_FILE"
    
    cat << EOF > "$CONFIG_FILE"
# Package Tracking Configuration
# Generated on: $(date '+%Y-%m-%d %H:%M:%S')

# Logging options
LOG_FILE="$LOG_FILE"
LOG_LEVEL="$LOG_LEVEL"  # Options: DEBUG, INFO, WARNING, ERROR

# Data storage
DATA_DIR="$DATA_DIR"

# Update settings
REPOS="$REPOS"
CHECK_INTERVAL=$CHECK_INTERVAL  # Update interval in seconds
NOTIFY="$NOTIFY"  # Whether to display notifications

# Network settings
TIMEOUT=$TIMEOUT  # Connection timeout in seconds
RETRY_COUNT=$RETRY_COUNT  # Number of retries for network operations
EOF

    log "INFO" "Configuration saved to $CONFIG_FILE"
}

# Function to create an initial configuration if it doesn't exist
initialize_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "INFO" "Creating initial configuration file"
        save_config
    fi
}

# Function to show usage information
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Track package updates and generate reports for Arch Linux packages.

Options:
  -u, --update               Force update package information regardless of interval
  -c, --compare              Compare package versions and generate report
  -s, --save                 Save current versions as previous versions
  -l, --log-level LEVEL      Set log level (DEBUG, INFO, WARNING, ERROR)
  -i, --interval SECONDS     Set update check interval in seconds (default: 86400)
  -d, --data-dir DIRECTORY   Set data directory for storing package information
  -r, --repos "REPO1 REPO2"  Set repositories to check (space-separated list)
  -t, --timeout SECONDS      Set connection timeout in seconds
  -h, --help                 Show this help message

Examples:
  $(basename "$0") --update            Force update package information
  $(basename "$0") --log-level DEBUG   Run with debug logging
  $(basename "$0") --interval 43200    Set update interval to 12 hours

Report bugs to: https://github.com/Githubguy132010/Arch-Linux-without-the-beeps/issues
EOF
}

# Function to parse command-line arguments
parse_arguments() {
    local force_update=false
    local do_compare=false
    local do_save=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--update)
                force_update=true
                shift
                ;;
            -c|--compare)
                do_compare=true
                shift
                ;;
            -s|--save)
                do_save=true
                shift
                ;;
            -l|--log-level)
                LOG_LEVEL="$2"
                shift 2
                ;;
            -i|--interval)
                CHECK_INTERVAL="$2"
                shift 2
                ;;
            -d|--data-dir)
                DATA_DIR="$2"
                # Update dependent file paths
                CURRENT_VERSIONS_FILE="${DATA_DIR}/current_versions.txt"
                PREVIOUS_VERSIONS_FILE="${DATA_DIR}/previous_versions.txt"
                UPDATES_FILE="${DATA_DIR}/package_updates.md"
                LAST_RUN_FILE="${DATA_DIR}/last_run.timestamp"
                # Create the directory if it doesn't exist
                mkdir -p "$DATA_DIR" 2>/dev/null || true
                shift 2
                ;;
            -r|--repos)
                REPOS="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Return parsed values
    echo "$force_update $do_compare $do_save"
}

# Main function
main() {
    log "INFO" "Starting package tracking process..."
    
    # Initialize configuration if needed
    initialize_config
    
    # Parse command-line arguments
    read -r force_update do_compare do_save <<< "$(parse_arguments "$@")"
    
    # Check if we need to update based on interval or force flag
    if [[ "$force_update" == "true" ]] || should_update; then
        # Check necessary commands before proceeding
        for cmd in pacman curl grep awk sort; do
            if ! check_command "$cmd"; then
                log "ERROR" "Required command not found: $cmd. Please install it and try again."
                exit 1
            fi
        done
        
        # Get current versions
        if ! get_current_versions; then
            log "ERROR" "Failed to get current package versions"
            exit 1
        fi
        
        # Flag that we should compare and save by default if we've updated
        do_compare=true
        do_save=true
    fi
    
    # Compare with previous versions if requested or if we've updated
    if [[ "$do_compare" == "true" ]]; then
        if ! compare_versions; then
            log "ERROR" "Failed to compare package versions"
            exit 1
        fi
    fi
    
    # After successful comparison, save current as previous for next run if requested
    if [[ "$do_save" == "true" ]]; then
        if ! save_versions_as_previous; then
            log "WARNING" "Failed to save current versions as previous"
        fi
    fi
    
    log "INFO" "Package tracking completed successfully"
    return 0
}

# Run the main function with all command-line arguments
main "$@"