#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="archlinux-nobeep"
iso_label="ARCH_NOBEEP_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Arch Linux No Beep <https://github.com/Githubguy132010/Arch-Linux-without-the-beeps>"
iso_application="Arch Linux No Beep Live/Rescue DVD"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
# Use simplified, general bootmodes
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

# Correctly formatted compression options for mksquashfs with XZ
# -b (block size) must be a power of 2, max 1M (1048576)
# -Xdict-size (dictionary size) should be a power of 2, max 1M
# -Xthreads=0 tells XZ to use all available CPU cores
if [ "$(nproc)" -ge 4 ]; then
  # For systems with 4 or more cores, use multi-threading and larger dictionary
  airootfs_image_tool_options=(
    '-comp' 'xz'
    '-Xbcj' 'x86'
    '-b' '1M'
    '-Xdict-size' '1M'
    '-Xthreads' '0'
  )
else
  # For systems with fewer than 4 cores, use a single thread and smaller dictionary
  airootfs_image_tool_options=(
    '-comp' 'xz'
    '-Xbcj' 'x86'
    '-b' '512K'
    '-Xdict-size' '512K'
    '-Xthreads' '1'
  )
fi

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)