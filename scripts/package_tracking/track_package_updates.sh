#!/usr/bin/env bash
#
# Script to track package updates for release notes
# This script compares current package versions with previous versions and generates a report

set -e

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Directory for storing package version data
DATA_DIR="/tmp/package-versions"
CURRENT_VERSIONS_FILE="${DATA_DIR}/current_versions.txt"
PREVIOUS_VERSIONS_FILE="${DATA_DIR}/previous_versions.txt"
UPDATES_FILE="${DATA_DIR}/package_updates.md"

# Create data directory if it doesn't exist
mkdir -p "${DATA_DIR}"

# Function to get current package versions
get_current_versions() {
    log "Getting current package versions..."
    
    # Make sure we're using an updated database
    pacman -Sy --noconfirm > /dev/null 2>&1
    
    # Get package list from packages.x86_64
    if [ -f "packages.x86_64" ]; then
        while read -r pkg; do
            # Skip empty lines and comments
            [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
            
            # Get version information for each package
            version=$(pacman -Si "$pkg" 2>/dev/null | grep "Version" | head -n 1 | awk '{print $3}')
            
            if [ -n "$version" ]; then
                echo "$pkg=$version" >> "${CURRENT_VERSIONS_FILE}.tmp"
            else
                warn "Could not get version for package: $pkg"
            fi
        done < "packages.x86_64"
        
        # Sort the file for easier comparison
        sort "${CURRENT_VERSIONS_FILE}.tmp" > "${CURRENT_VERSIONS_FILE}"
        rm "${CURRENT_VERSIONS_FILE}.tmp"
    else
        warn "packages.x86_64 file not found!"
        return 1
    fi
    
    log "Current package versions saved to ${CURRENT_VERSIONS_FILE}"
}

# Function to save current versions as the new previous versions
save_versions_as_previous() {
    if [ -f "${CURRENT_VERSIONS_FILE}" ]; then
        cp "${CURRENT_VERSIONS_FILE}" "${PREVIOUS_VERSIONS_FILE}"
        log "Saved current versions as previous for next comparison."
    else
        warn "No current versions file found to save as previous."
    fi
}

# Function to compare current with previous versions
compare_versions() {
    log "Comparing current package versions with previous versions..."
    
    # If previous versions file doesn't exist, create an empty one
    if [ ! -f "${PREVIOUS_VERSIONS_FILE}" ]; then
        warn "No previous versions file found. This might be the first run."
        touch "${PREVIOUS_VERSIONS_FILE}"
    fi
    
    # Create updates file with header
    echo "## 📦 Package Updates" > "${UPDATES_FILE}"
    echo "" >> "${UPDATES_FILE}"
    
    # Track if we found any updates
    found_updates=false
    
    while IFS='=' read -r pkg current_version; do
        # Get previous version of this package
        previous_version=$(grep "^${pkg}=" "${PREVIOUS_VERSIONS_FILE}" | cut -d'=' -f2)
        
        # If package is new or has a different version
        if [ -z "$previous_version" ]; then
            echo "- ➕ New package: **${pkg}** (${current_version})" >> "${UPDATES_FILE}"
            found_updates=true
        elif [ "$previous_version" != "$current_version" ]; then
            echo "- 🔄 Updated: **${pkg}** (${previous_version} → ${current_version})" >> "${UPDATES_FILE}"
            found_updates=true
        fi
    done < "${CURRENT_VERSIONS_FILE}"
    
    # Check for packages that were removed
    while IFS='=' read -r pkg previous_version; do
        if ! grep -q "^${pkg}=" "${CURRENT_VERSIONS_FILE}"; then
            echo "- ❌ Removed: **${pkg}** (was ${previous_version})" >> "${UPDATES_FILE}"
            found_updates=true
        fi
    done < "${PREVIOUS_VERSIONS_FILE}"
    
    # If no updates were found, add a note
    if [ "$found_updates" = false ]; then
        echo "No package updates since the previous release." >> "${UPDATES_FILE}"
    fi
    
    log "Package comparison complete. Results written to ${UPDATES_FILE}"
}

# Main function
main() {
    log "Starting package tracking process..."
    
    # Get current versions
    get_current_versions
    
    # Compare with previous versions
    compare_versions
    
    # After successful comparison, save current as previous for next run
    save_versions_as_previous
    
    log "Package tracking completed."
}

# Run the main function
main