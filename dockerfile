FROM archlinux:latest AS builder

# Set up parallel downloads and other optimizations
COPY pacman.conf /etc/pacman.conf

# Update system and install necessary packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
    git \
    archiso \
    grub \
    syslinux \
    systemd \
    efibootmgr \
    dosfstools \
    mtools \
    arch-install-scripts \
    bash \
    base-devel \
    && pacman -Scc --noconfirm

# Set the working directory
WORKDIR /build

# Copy only necessary files for package installation
COPY packages.x86_64 bootstrap_packages.x86_64 profiledef.sh ./

# Create a new final image
FROM builder AS final

# Set the working directory
WORKDIR /workdir

# Copy the rest of the files
COPY . .

# Use an entrypoint script for better flexibility
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["build"]
