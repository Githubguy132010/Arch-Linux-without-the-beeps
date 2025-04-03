#!/bin/bash
set -e

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log "Selecting fastest mirrors..."

# Create mirror directory if it doesn't exist
mkdir -p airootfs/etc/pacman.d/
cp /etc/pacman.d/mirrorlist airootfs/etc/pacman.d/mirrorlist.backup 2>/dev/null || true

# Install reflector if not already installed
if ! command -v reflector &> /dev/null; then
    log "Installing reflector..."
    pacman -Sy --noconfirm reflector
fi

# Generate mirror list with reflector
log "Generating optimized mirror list..."
reflector --latest 20 \
          --sort rate \
          --protocol https \
          --save airootfs/etc/pacman.d/mirrorlist

log "Mirror selection complete!"