FROM archlinux:latest

# Install necessary packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm git archiso grub

# Set the working directory
WORKDIR /workdir

# Copy files into the container
COPY . .

# Instead of running mkarchiso here, we leave it for later execution
# Create an entrypoint or leave it to manual execution
CMD ["/bin/bash"]
