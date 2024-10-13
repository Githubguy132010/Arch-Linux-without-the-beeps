
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
   - **Pushes** and **Pull Requests** to the `main` branch
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

   Keep in mind that you will need a Personal Access Token (PAT) and to modify the workflow file to include your PAT.

### GitHub Actions Workflow Example

Here's the full GitHub Actions workflow used for automated builds and releases:

```yaml
name: Build ISO

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  schedule:
    # Runs every day at midnight
    - cron: '0 0 * * *'

jobs:
  build:
    runs-on: ubuntu-latest

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
          iso_file=\$(ls /workdir/out/*.iso | head -n 1) &&
          mv \$iso_file /workdir/out/Arch.iso
          "

      - name: Copy ISO to Host
        run: |
          docker cp arch-container:/workdir/out/Arch.iso ${{ github.workspace }}/
      
      - name: Create GitHub Release
        uses: actions/create-release@v1.1.4
        env:
          GITHUB_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
        with:
          tag_name: v${{ steps.date.outputs.date }}-release
          release_name: ${{ steps.date.outputs.date }}
          body: |
            This release contains the Arch Linux ISO built on ${{ steps.date.outputs.date }}.
          draft: false
          prerelease: false

      - name: Upload ISO to GitHub Release
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
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
