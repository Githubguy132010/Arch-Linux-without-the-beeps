#!/bin/bash
set -eo pipefail

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

# --- Atomic File Operations ---
safe_write() {
    local content="$1"
    local target_file="$2"
    local temp_file
    temp_file=$(mktemp)

    echo -e "$content" > "$temp_file"
    mv "$temp_file" "$target_file"
}

# Function to build the ISO
build_iso() {
    local output_dir="${1:-out}"
    local work_dir="${2:-work}"

    if ! [[ "$output_dir" =~ ^[a-zA-Z0-9_-]+$ ]] || \
       ! [[ "$work_dir" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid characters in directory names. Only alphanumeric, underscore, and hyphen are allowed."
    fi
    
    log "Starting Arch Linux ISO build process..."
    log "Work directory: $work_dir"
    log "Output directory: $output_dir"
    
    mkdir -p "$output_dir" "$work_dir"
    
    log "Selecting fastest mirrors..."
    if ! ./scripts/select-mirrors.sh; then
        error "Mirror selection failed. Aborting build."
    fi
    
    log "Disabling PC speaker in airootfs configuration..."
    mkdir -p "airootfs/etc/modprobe.d/"
    safe_write "blacklist pcspkr\nblacklist snd_pcsp" "airootfs/etc/modprobe.d/nobeep.conf"

    log "Creating custom hook to disable beeps..."
    mkdir -p "airootfs/usr/share/libalpm/hooks/"
    read -r -d '' HOOK_CONTENT << 'EOF'
[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = *

[Action]
Description = Disabling system beeps in various configuration files...
When = PostTransaction
Exec = /bin/bash -c "mkdir -p /etc/modprobe.d && { echo -e 'blacklist pcspkr\nblacklist snd_pcsp' > /etc/modprobe.d/nobeep.conf.tmp && mv /etc/modprobe.d/nobeep.conf.tmp /etc/modprobe.d/nobeep.conf; } && if [ -f /etc/inputrc ]; then grep -q 'set bell-style none' /etc/inputrc || echo 'set bell-style none' >> /etc/inputrc; fi"
EOF
    safe_write "$HOOK_CONTENT" "airootfs/usr/share/libalpm/hooks/99-no-beep.hook"
    
    log "Adding bash configuration to disable terminal bell..."
    mkdir -p "airootfs/etc/skel/"
    safe_write "# Disable terminal bell\nbind 'set bell-style none'" "airootfs/etc/skel/.bashrc"

    log "Setting bell-style none in global inputrc..."
    mkdir -p "airootfs/etc"
    safe_write "set bell-style none" "airootfs/etc/inputrc"
    
    export JOBS=$(nproc)
    log "Using $JOBS processors for parallel compression"
    
    log "Building Arch ISO with mkarchiso..."
    if mkarchiso -v -w "$work_dir" -o "$output_dir" .; then
        log "ISO build completed successfully!"
        log "ISO available at: $output_dir"
    else
        error "ISO build failed!"
    fi
}

clean() {
    log "Cleaning up build artifacts..."
    find work -mindepth 1 -delete
    log "Cleanup complete."
}

validate() {
    log "Validating configuration..."
    
    # Check for required files
    for f in packages.x86_64 profiledef.sh pacman.conf; do
        if [ ! -f "$f" ]; then
            error "$f file not found!"
        fi
    done
    
    # Check for executable permissions
    if [ ! -x "profiledef.sh" ]; then
        error "profiledef.sh is not executable!"
    fi

    # Validate profiledef.sh content
    if ! grep -q "iso_name=" "profiledef.sh"; then
        error "profiledef.sh is missing the 'iso_name' variable."
    fi
    
    # Validate package list syntax
    for list in packages.x86_64 bootstrap_packages.x86_64; do
        if [ -f "$list" ] && grep -qE '[^a-zA-Z0-9_+-]' "$list"; then
            error "$list contains invalid characters. Only alphanumeric, underscore, hyphen, and plus are allowed."
        fi
    done

    # Sort and deduplicate package lists
    log "Sorting and deduplicating package lists..."
    for list in packages.x86_64 bootstrap_packages.x86_64; do
        if [ -f "$list" ]; then
            sort -u "$list" -o "$list"
        fi
    done
    
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