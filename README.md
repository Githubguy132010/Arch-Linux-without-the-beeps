

# Arch Linux Without the Beeps

This repository provides a customized Arch Linux ISO with the system beeps disabled, ideal for users who prefer a quieter environment.

## Features

- **Silent Mode**: The systemd-boot beep and other annoying beeps are completely disabled.
- **Arch Linux Base**: Built on the latest Arch Linux, providing a clean and minimal system.
- **Custom ISO**: Easily build and download a custom ISO with this configuration.
- **Daily Automated Build**: ISO builds are automatically generated and released daily.

## Workflow Overview

This project uses GitHub Actions to automatically build and release an Arch Linux ISO with the system bell disabled. The workflow includes the following steps:

1. **Checkout Repository**: Pulls the latest files from the repository.
2. **Build Environment Setup**: A Docker container simulates the Arch Linux environment.
3. **Build ISO**: The Arch ISO is customized and built using `mkarchiso`.
4. **Upload ISO**: The ISO is uploaded as a release on GitHub with a version tag.
5. **Silent Configuration**: Ensures that system beeps are turned off across all configurations.

## How to Use

1. **Clone the repository**:

   ```bash
   git clone https://github.com/Githubguy132010/Arch-Linux-without-the-beeps.git
   ```
2. **Run the workflow**

  You can run the workflow manually by going to Actions > Build ISO and click on run Workflow.
  Keep un mind you are going to need a PAT (Personal access Token) and you need to edit the Workflow to reflect your PAT.

2. **Automated Workflow**: The GitHub Actions workflow automatically triggers on:
   - **Pushes** and **Pull Requests** to the `main` branch
   - **Scheduled daily builds** at midnight (UTC)

3. **Download the ISO**:
   - Visit the [releases page](https://github.com/Githubguy132010/Arch-Linux-without-the-beeps/releases) to download the latest ISO.

## Configuration Details

This project disables the systemd-boot by modifying several configuration files. The changes are applied during the ISO build process.


## GitHub Actions Workflow

The workflow file for building and releasing the custom ISO is located at `.github/workflows/build-iso.yml`. Here's the workflow snippet:

```yaml
name: Build ISO Without Beeps

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

      - name: Rename ISO to ArchGUI-NoBeeps.iso
        run: |
          docker exec arch-container bash -c "
          iso_file=\$(ls /workdir/out/*.iso | head -n 1) &&
          mv \$iso_file /workdir/out/Arch.iso
          "

      - name: Copy ISO to Host
        run: |
          docker cp arch-container:/workdir/out/Arch.iso ${{ github.workspace }}/
      
      - name: Create GitHub Release
        uses: actions/create-release@v1.1.0
        env:
          GITHUB_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
        with:
          tag_name: v${{ steps.date.outputs.date }}-release
          release_name: ${{ steps.date.outputs.date }}
          body: |
            This release contains the Arch Linux ISO built on ${{ steps.date.outputs.date }}
          draft: false
          prerelease: false

      - name: Upload ISO to GitHub Release
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ${{ github.workspace }}/ArchGUI-NoBeeps.iso
          asset_name: Arch.iso
          asset_content_type: application/octet-stream

      - name: Clean Up
        run: |
          docker stop arch-container
          docker rm arch-container
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
