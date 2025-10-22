#!/bin/bash
set -eo pipefail

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log "Selecting fastest mirrors..."

# Create mirror directory if it doesn't exist
mkdir -p airootfs/etc/pacman.d/

# Backup existing mirrorlist if it exists
if [ -f /etc/pacman.d/mirrorlist ]; then
    cp /etc/pacman.d/mirrorlist airootfs/etc/pacman.d/mirrorlist.backup 2>/dev/null || {
        warn "Failed to backup mirrorlist, continuing without backup."
    }
else
    warn "No system mirrorlist found to backup."
fi

# Install reflector if not already installed
if ! command -v reflector &> /dev/null; then
    log "Installing reflector..."
    if ! pacman -Sy --noconfirm reflector; then
        error "Failed to install reflector. Aborting mirror selection."
    fi
fi

# Generate mirror list with reflector
log "Generating optimized mirror list..."
if ! reflector --latest 20 --sort rate --protocol https --download-timeout 15 --save airootfs/etc/pacman.d/mirrorlist; then
    error "Reflector failed to generate a new mirror list. The build cannot continue."
fi

# Verify that the new mirrorlist is not empty
if [ ! -s airootfs/etc/pacman.d/mirrorlist ]; then
    error "The generated mirrorlist is empty. Aborting build."
fi

log "Mirror selection complete!"