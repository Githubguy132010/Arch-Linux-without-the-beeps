
---

# Arch Linux Without the Beeps

This repository provides a customized Arch Linux ISO with the system beeps disabled, ideal for users who prefer a quieter environment.

## Features

- **Silent Mode**: The systemd-boot beep and other annoying beeps are completely disabled.
- **Arch Linux Base**: Built on the latest Arch Linux, providing a clean and minimal system.
- **Custom ISO**: Easily build and download a custom ISO with this configuration.
- **Daily Automated Build**: ISO builds are automatically generated and released daily (if using GitHub Actions).

---

## How to Build the ISO Locally

If you prefer to build the Arch Linux ISO locally, you can use Docker to set up a containerized environment. Here's how:

### Prerequisites

Make sure you have Docker installed on your system.

### Steps to Build Locally

1. **Clone the repository**:

   ```bash
   git clone https://github.com/Githubguy132010/Arch-Linux-without-the-beeps.git
   cd Arch-Linux-without-the-beeps
   ```

2. **Build the Docker Image**:

   Build the Docker image, which will be used to build the ISO.

   ```bash
   docker build -t arch-iso-builder .
   ```

3. **Build the ISO in the container**:

   Build the ISO with this command:

   ```bash
   docker run --rm --privileged -v $(pwd):/workdir arch-iso-builder bash -c "mkarchiso -v -w workdir/ -o out/ ."
   ```

4. **Retrieve the ISO**:

   Once the process completes, the ISO will be available in the `out/` directory within your local folder as `Arch.iso`.

### Dockerfile Used for Local Builds

The following `Dockerfile` is used to build the ISO locally:

```Dockerfile
# Use the official Arch Linux image as the base
FROM archlinux:latest

# Update system and install necessary packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm git archiso grub

# Create a directory for the workspace
WORKDIR /workdir

# Copy the entire repository into the container
COPY . .

# Set the output directory as a volume so you can retrieve the ISO later
VOLUME /workdir/out

# The default command just keeps the container running
CMD [ "sleep", "infinity" ]
```

---

## How to Use GitHub Actions (Automated Workflow)

This repository also includes a GitHub Actions workflow for building and releasing the ISO automatically on GitHub. 

### How It Works:

1. **Automated Workflow**: The workflow is triggered by:
   - **A manual run**
   - **Scheduled daily builds** at midnight (UTC)

2. **Download the ISO**:
   - Visit the [releases page](https://github.com/Githubguy132010/Arch-Linux-without-the-beeps/releases) to download the latest ISO.

### GitHub Actions Workflow Overview

The GitHub Actions workflow automatically builds and releases the ISO. Here’s a quick overview:

1. **Checkout Repository**: Pulls the latest files from the repository.
2. **Build Environment Setup**: A Docker container simulates the Arch Linux environment.
3. **Build ISO**: The Arch ISO is customized and built using `mkarchiso`.
4. **Upload ISO**: The ISO is uploaded as a release on GitHub with a version tag.
5. **Silent Configuration**: Ensures that system beeps are turned off across all configurations.

### How to Trigger the GitHub Workflow

1. **Run the workflow manually**:
   You can run the workflow manually by going to **Actions > Build ISO** and clicking on **Run Workflow**. 


### GitHub Actions Workflow Example

Here's the full GitHub Actions workflow used for automated builds and releases:

```yaml
name: Build ISO

on:
  workflow_dispatch:
  schedule:
    # Run the workflow every day at midnight
    - cron: 0 0 * * *

jobs:
  build:
    runs-on: ubuntu-latest  # Use a standard runner

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Arch Linux Container
        run: |
          docker run --privileged --name arch-container -d -v ${{ github.workspace }}:/workdir archlinux:latest sleep infinity

      - name: Build ISO in Arch Container
        run: |
          docker exec arch-container bash -c "
          pacman -Syu --noconfirm &&
          pacman -S --noconfirm git archiso grub &&
          cd /workdir &&
          mkarchiso -v -w workdir/ -o out/ .
          "

      - name: Rename ISO to Arch.iso
        run: |
          docker exec arch-container bash -c "
          # Find the created ISO (assuming only one .iso file in the output directory)
          iso_file=\$(ls /workdir/out/*.iso | head -n 1) &&
          mv \$iso_file /workdir/out/Arch.iso
          "

      - name: List ISO files
        run: |
          # List files in the output directory to verify renaming
          docker exec arch-container bash -c "ls -l /workdir/out/"

      - name: Copy ISO to Host
        run: |
          # Copy the renamed ISO to the host
          docker cp arch-container:/workdir/out/Arch.iso ${{ github.workspace }}/

      - name: Get current date
        id: date
        run: echo "date=$(date +'%Y-%m-%d')" >> $GITHUB_OUTPUT

      # Create a release on GitHub using Personal Access Token (PAT)
      - name: Create GitHub Release
        id: create_release  # Adding an ID to reference the release step
        uses: actions/create-release@v1.1.4
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v${{ github.run_id }}-release
          release_name: "Arch Linux Release"
          body: |
            This release contains the Arch Linux ISO built on ${{ steps.date.outputs.date }}.
          draft: false
          prerelease: false

      # Upload the ISO to the GitHub release with a specific, predictable name
      - name: Upload ISO to GitHub Release
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ${{ github.workspace }}/Arch.iso
          asset_name: Arch.iso
          asset_content_type: application/octet-stream

      - name: Clean Up
        run: |
          docker stop arch-container
          docker rm arch-container
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
