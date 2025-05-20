# Stage 1: Builder with necessary tools
FROM archlinux:latest AS builder

# Environment variable for non-interactive pacman
ENV PACMAN_OPTS --noconfirm

# Setup pacman.conf for parallel downloads (if customized)
# This line should be kept if pacman.conf provides tangible benefits like custom repositories or mirror lists.
# If pacman.conf is default or minor, consider removing this COPY to improve caching if it changes unnecessarily.
# For now, assume it's beneficial and keep it.
COPY pacman.conf /etc/pacman.conf

# Update system and install build dependencies
# Combining Syu and S into one layer is good. Scc cleans cache, also good for image size.
RUN pacman -Syu ${PACMAN_OPTS} &&     pacman -S ${PACMAN_OPTS} --needed     git     archiso     grub     base-devel     && pacman -Scc ${PACMAN_OPTS}

# Stage 2: Final image with entrypoint
# Based on builder to inherit tools
FROM builder AS final

# Set the working directory, which will be the mount point for repo files in CI
WORKDIR /workdir

# Copy only the entrypoint script. The build process relies on the
# workspace being mounted to /workdir by the CI runner, containing all other necessary files (profiledef.sh, packages, airootfs, etc.).
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Default command for the entrypoint (e.g., "build", "validate", "shell")
CMD ["build"]
