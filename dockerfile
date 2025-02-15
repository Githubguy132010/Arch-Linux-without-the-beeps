FROM archlinux:latest

# Install necessary packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm git archiso grub

# Set the working directory
WORKDIR /workdir

# Copy files into the container
COPY . .

# Run mkarchiso to build the ISO
RUN mkarchiso -v -w /workdir/workdir -o /workdir/out .

# Create an entrypoint or leave it to manual execution
CMD ["/bin/bash"]
