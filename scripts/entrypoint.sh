#!/bin/bash
set -e

# Colors for better output
RED='\033[0;31m'
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

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Function to build the ISO
build_iso() {
    local output_dir="${1:-out}"
    local work_dir="${2:-work}"
    
    log "Starting Arch Linux ISO build process..."
    log "Work directory: $work_dir"
    log "Output directory: $output_dir"
    
    # Create necessary directories
    mkdir -p "$output_dir"
    mkdir -p "$work_dir"
    
    # Run the mirror selection script
    log "Selecting fastest mirrors..."
    ./scripts/select-mirrors.sh || warn "Mirror selection failed, continuing with default mirrors"
    
    # Disable PC speaker module in airootfs if present
    if [ -f "airootfs/etc/modprobe.d/nobeep.conf" ] \
       && grep -q "pcspkr" airootfs/etc/modprobe.d/nobeep.conf 2>/dev/null \
       && grep -q "snd_pcsp" airootfs/etc/modprobe.d/nobeep.conf 2>/dev/null; then
        log "PC speaker already disabled in airootfs configuration."
    else
        log "Disabling PC speaker in airootfs configuration..."
        mkdir -p airootfs/etc/modprobe.d/
        echo "blacklist pcspkr" > airootfs/etc/modprobe.d/nobeep.conf
        echo "blacklist snd_pcsp" >> airootfs/etc/modprobe.d/nobeep.conf
    fi
    
    # Create a custom hook to disable beeps in various config files
    if [ ! -f "airootfs/usr/share/libalpm/hooks/99-no-beep.hook" ]; then
        log "Creating custom hook to disable beeps..."
        mkdir -p airootfs/usr/share/libalpm/hooks/
        cat > airootfs/usr/share/libalpm/hooks/99-no-beep.hook << 'EOF'
[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = *

[Action]
Description = Disabling system beeps in various configuration files...
When = PostTransaction
Exec = /bin/bash -c "mkdir -p /etc/modprobe.d && echo 'blacklist pcspkr' > /etc/modprobe.d/nobeep.conf && echo 'blacklist snd_pcsp' >> /etc/modprobe.d/nobeep.conf && if [ -f /etc/inputrc ]; then grep -q 'set bell-style none' /etc/inputrc || echo 'set bell-style none' >> /etc/inputrc; fi"
EOF
    fi
    
    # Add settings to disable terminal bell in bash
    if [ ! -f "airootfs/etc/skel/.bashrc" ]; then
        log "Adding bash configuration to disable terminal bell..."
        mkdir -p airootfs/etc/skel/
        echo "# Disable terminal bell" > airootfs/etc/skel/.bashrc
        echo "bind 'set bell-style none'" >> airootfs/etc/skel/.bashrc
    fi

    # Set bell-style none in global inputrc
    if [ ! -f "airootfs/etc/inputrc" ]; then
        log "Setting bell-style none in global inputrc..."
        mkdir -p airootfs/etc
        echo "set bell-style none" > airootfs/etc/inputrc
    fi
    
    # Optimize the build process with parallel compression
    export JOBS=$(nproc)
    log "Using $JOBS processors for parallel compression"
    
    # Note: We don't modify profiledef.sh anymore as -Xthreads is not supported by mksquashfs
    # The profiledef.sh file already has proper XZ compression settings
    
    # Run mkarchiso with verbose option and handle errors
    log "Building Arch ISO with mkarchiso..."
    if mkarchiso -v -w "$work_dir" -o "$output_dir" .; then
        log "ISO build completed successfully!"
        log "ISO available at: $output_dir"
    else
        error "ISO build failed!"
    fi
}

# Function to clean up build artifacts
clean() {
    log "Cleaning up build artifacts..."
    rm -rf work/*
    log "Cleanup complete."
}

# Function to validate the configuration
validate() {
    log "Validating configuration..."
    
    # Check if packages.x86_64 exists
    if [ ! -f "packages.x86_64" ]; then
        error "packages.x86_64 file not found!"
    fi
    
    # Check if profiledef.sh exists and is executable
    if [ ! -x "profiledef.sh" ]; then
        error "profiledef.sh not found or not executable!"
    fi
    
    # Check if pacman.conf exists
    if [ ! -f "pacman.conf" ]; then
        error "pacman.conf not found!"
    fi
    
    # Sort and deduplicate package lists
    log "Sorting and deduplicating package lists..."
    if [ -f "packages.x86_64" ]; then
        sort -u packages.x86_64 -o packages.x86_64
    fi
    
    if [ -f "bootstrap_packages.x86_64" ]; then
        sort -u bootstrap_packages.x86_64 -o bootstrap_packages.x86_64
    fi
    
    log "Configuration appears valid."
}

# Main switch
case "$1" in
    build)
        validate
        build_iso "$2" "$3"
        ;;
    clean)
        clean
        ;;
    validate)
        validate
        ;;
    shell)
        log "Starting interactive shell..."
        exec /bin/bash
        ;;
    *)
        log "Usage: $0 {build|clean|validate|shell} [output_dir] [work_dir]"
        log ""
        log "Commands:"
        log "  build      - Build the Arch Linux ISO"
        log "  clean      - Clean up build artifacts"
        log "  validate   - Validate the configuration"
        log "  shell      - Start an interactive shell"
        exit 1
        ;;
esac

exit 0