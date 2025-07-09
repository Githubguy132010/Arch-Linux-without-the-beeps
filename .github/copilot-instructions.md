# Copilot Instructions: Arch Linux Without the Beeps

## Project Overview

This is a specialized Arch Linux ISO builder that creates a completely silent live environment by systematically disabling all system beeps at multiple layers. The project uses `mkarchiso` (Arch Linux's official ISO creation tool) with custom configurations to build bootable ISOs with comprehensive beep suppression.

## Architecture & Core Components

### 1. ISO Build System (archiso-based)
- **`profiledef.sh`**: Main build configuration defining ISO metadata, compression settings, and build modes
- **`packages.x86_64`**: Complete package list for the live environment (deduplicated and sorted)
- **`bootstrap_packages.x86_64`**: Essential packages needed during the build process
- **`pacman.conf`**: Custom pacman configuration with optimized mirror settings
- **`airootfs/`**: File system overlay that becomes the root filesystem of the live ISO

### 2. Multi-Layer Beep Suppression Strategy
The project implements a comprehensive 5-layer approach to silence ALL system beeps (kernel, terminal, X11, etc.):

**Layer 1 - Kernel Module Blacklisting** (`airootfs/etc/modprobe.d/`)
- `nobeep.conf`: Blacklists `pcspkr`, `snd_pcsp`, and hardware-specific beep modules
- `alsa-no-beep.conf`: Disables ALSA beep modes for Intel HDA drivers
- Uses both `blacklist` and `install /bin/true` patterns for complete suppression

**Layer 2 - Systemd Services** (`airootfs/etc/systemd/system/`)
- `no-beep.service`: Early boot service (runs before `sysinit.target`) that forcibly unloads PC speaker modules
- `no-console-beep.service`: Post-boot service that disables virtual terminal bells using `setterm`
- Both use `Type=oneshot` with `RemainAfterExit=yes` for persistent state

**Layer 3 - Terminal/Shell Configuration** (`airootfs/etc/skel/`)
- `.inputrc`: Sets `bell-style none` for readline-based applications
- `.bashrc`: Uses `bind 'set bell-style none'` for bash-specific bell disabling
- Terminal emulator configs: Alacritty (`alacritty.yml`), XTerm (`.Xresources`), Konsole (`konsolerc`)

**Layer 4 - X11/GUI Environment** (`airootfs/etc/X11/`)
- `xinit/xinitrc.d/50-no-bell.sh`: Runs `xset -b` to disable X11 bell on session start
- `xorg.conf.d/50-no-bell.conf`: Xorg input configuration to disable keyboard bells

**Layer 5 - Boot Parameters** (in `efiboot/` and `syslinux/`)
- Kernel parameters: `quiet vga=current loglevel=3` to minimize boot noise
- Applied across all boot methods (UEFI, BIOS, PXE)

### 3. Containerized Build System
- **`dockerfile`**: Multi-stage build with Arch Linux base, archiso tools, and optimized pacman config
- **`scripts/entrypoint.sh`**: Sophisticated build orchestrator with validation, mirror selection, and error handling
- **`scripts/select-mirrors.sh`**: Automatically selects fastest mirrors for build performance

### 4. CI/CD Pipeline (`.github/workflows/`)
- **`build.yml`**: Daily automated builds with checksums, package tracking, and GitHub releases
- **`release-notes.yml`**: Automated release notes generation with categorized commit analysis
- Uses Docker privileged mode for loop device access required by `mkarchiso`

## Critical Developer Workflows

### Local ISO Building
```bash
# Build Docker image
docker build -t arch-iso-builder .

# Build ISO (requires privileged mode for loop devices)
docker run --rm --privileged -v $(pwd):/workdir arch-iso-builder build out work
```

### Testing Beep Suppression
- Use `echo -e "\a"` to test terminal bell suppression
- Check `lsmod | grep -E 'pcspkr|snd_pcsp'` to verify module blacklisting
- Use `xset q | grep bell` to check X11 bell status

### Package Management
- Always run `sort -u packages.x86_64 -o packages.x86_64` after modifying package lists
- Use `scripts/package_tracking/track_package_updates.sh` for release notes generation (tracks package updates)
- Bootstrap packages must be minimal - only what's needed for the build process

## Project-Specific Conventions

### File Organization
- **Configuration cascading**: System-wide configs in `airootfs/etc/`, user defaults in `airootfs/etc/skel/`
- **Service ordering**: Early services use `Before=sysinit.target`, late services use `After=multi-user.target`
- **Modular approach**: Each beep source gets dedicated configuration files rather than monolithic configs

### Beep Suppression Patterns
- **Defense in depth**: Always implement multiple layers - kernel, systemd, shell, GUI
- **Graceful fallbacks**: Use `|| true` in shell scripts to continue if modules aren't loaded
- **Comprehensive coverage**: Target all possible beep sources (PC speaker, ALSA, terminals, X11)

### Build System Conventions
- **Error handling**: All build scripts use `set -e` and explicit error checking
- **Logging**: Consistent color-coded logging in entrypoint script (`log()`, `warn()`, `error()`)
- **Validation**: Always validate configuration before building (`validate()` function)

## Integration Points

### archiso Integration
- Extends standard archiso profiles with custom `profiledef.sh` and `airootfs/` overlay
- Compression settings optimized for build performance (`airootfs_image_tool_options`)
- Uses standard archiso hooks but adds custom beep suppression hooks

### GitHub Actions Integration
- Automatic daily builds triggered by cron schedule
- Package version tracking for detailed release notes
- Checksum generation (SHA256/SHA512) for security verification

### Docker Integration
- Build environment isolation using official `archlinux:latest` base
- Persistent package cache for faster rebuilds
- Privileged container access for loop device mounting

## Key Files for Understanding Architecture

- **`profiledef.sh`**: Start here to understand the overall build configuration
- **`airootfs/etc/modprobe.d/nobeep.conf`**: Core kernel-level beep suppression
- **`scripts/entrypoint.sh`**: Complete build orchestration logic
- **`docs/BEEP_DISABLING_MECHANISMS.md`**: Comprehensive technical documentation of all suppression mechanisms
- **`.github/workflows/build.yml`**: CI/CD pipeline and release automation

## Common Tasks for AI Agents

- **Adding new beep suppression**: Follow the 5-layer pattern, add configs to appropriate `airootfs/` subdirectories
- **Package management**: Modify `packages.x86_64`, ensure deduplication, update bootstrap packages if needed
- **Service modifications**: Use systemd service templates in `airootfs/etc/systemd/system/`
- **Build improvements**: Modify `scripts/entrypoint.sh` for build logic, `dockerfile` for environment changes
- **Documentation updates**: Update both `README.md` and `docs/BEEP_DISABLING_MECHANISMS.md` for user-facing changes

This project prioritizes reliability and completeness over simplicity - every beep source must be addressed systematically across all layers of the system.
