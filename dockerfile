# Use the official Arch Linux image as the base
FROM archlinux:latest

# Update system and install necessary packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm git archiso grub

# Create a directory for the workspace
WORKDIR /workdir

# Copy the entire repository into the container
COPY . .

# Build the Arch ISO
RUN mkarchiso -v -w workdir/ -o out/ .

# Rename the generated ISO to Arch.iso (if only one ISO is generated)
RUN iso_file=$(ls out/*.iso | head -n 1) && \
    mv $iso_file out/Arch.iso

# Set the output directory as a volume so you can retrieve the ISO later
VOLUME /workdir/out

# The default command just keeps the container running
CMD [ "sleep", "infinity" ]
