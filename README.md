---
# Arch Linux Without the Beeps

This repository provides a customized Arch Linux ISO with the system beeps disabled, ideal for users who prefer a quieter environment.

## Features

- **Silent Mode**: The systemd-boot beep and other annoying beeps are completely disabled.
- **Arch Linux Base**: Built on the latest Arch Linux, providing a clean and minimal system.
- **Custom ISO**: Easily build and download a custom ISO with this configuration.
- **Daily Automated Build**: ISO builds are automatically generated and released daily (if using GitHub Actions).
- **Automatic Release Notes**: Release notes are automatically generated for each new release with categorized changes.

---

## How to Build the ISO Locally

If you prefer to build the Arch Linux ISO locally, you can use Docker to set up a containerized environment. Here's how:

### Prerequisites

Make sure you have Docker installed on your system.

#### Docker Installation

To install Docker, follow the instructions for your operating system:

- **Windows**:
  1. Download and install Docker Desktop from [Docker's official website](https://www.docker.com/products/docker-desktop).
  2. Follow the installation instructions and start Docker Desktop.

- **macOS**:
  1. Download and install Docker Desktop from [Docker's official website](https://www.docker.com/products/docker-desktop).
  2. Follow the installation instructions and start Docker Desktop.

- **Linux**:
  1. Follow the official Docker installation guide for your distribution:
     - [Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
     - [Debian](https://docs.docker.com/engine/install/debian/)
     - [Fedora](https://docs.docker.com/engine/install/fedora/)
     - [CentOS](https://docs.docker.com/engine/install/centos/)
  2. Start the Docker service:
     ```bash
     sudo systemctl start docker
     sudo systemctl enable docker
     ```

#### Common Troubleshooting Tips

- **Permission Errors**: If you encounter permission errors, try adding your user to the Docker group:
  ```bash
  sudo usermod -aG docker $USER
  newgrp docker
  ```

- **Network Issues**: Ensure your internet connection is stable. If problems persist, try using a different network or adjusting Docker's network settings.

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
   docker run --rm --privileged -v $(pwd):/workdir arch-iso-builder bash -c "build out work"
   ```

4. **Retrieve the ISO**:

   Once the process completes, the ISO will be available in the `out/` directory within your local folder as `Arch.iso`.

## How to Use GitHub Actions (Automated Workflow)

This repository also includes a GitHub Actions workflow for building and releasing the ISO automatically on GitHub. 

### How It Works:

1. **Automated Workflow**: The workflow is triggered by:
   - **A manual run**
   - **Scheduled daily builds** at midnight (UTC)

2. **Download the ISO**:
   - Visit the [releases page](https://github.com/Githubguy132010/Arch-Linux-without-the-beeps/releases) to download the latest ISO.

### GitHub Actions Workflow Overview

The GitHub Actions workflow automatically builds and releases the ISO. Here's a quick overview:

1. **Checkout Repository**: Pulls the latest files from the repository.
2. **Build Environment Setup**: A Docker container simulates the Arch Linux environment.
3. **Build ISO**: The Arch ISO is customized and built using `mkarchiso`.
4. **Upload ISO**: The ISO is uploaded as a release on GitHub with a version tag.
5. **Silent Configuration**: Ensures that system beeps are turned off across all configurations.

### Automatic Release Notes Generation

This repository includes an automated workflow that generates comprehensive release notes whenever a new release is created. This feature helps contributors and users understand what changes were made between releases.

#### How It Works

- **When**: The workflow is triggered automatically when a new release is created in GitHub.
- **What**: It generates release notes by analyzing commits between the current and previous release tags.
- **Format**: The release notes are organized into categories:
  - 🚀 **Features & Enhancements**: New features and improvements
  - 🐛 **Bug Fixes**: Resolved issues and bugs
  - 🔧 **Maintenance & Refactoring**: Code refactoring, documentation updates, and other maintenance tasks
  - 📝 **Other Changes**: Any other commits not fitting in the above categories

#### Commit Message Guidelines

To get the most out of the automatic release notes generation, follow these commit message conventions:

- Use prefixes like `feat:`, `fix:`, `docs:`, `refactor:`, `chore:` to categorize your commits
- Write clear and descriptive commit messages that explain what the change does
- Examples:
  - `feat: add support for XYZ hardware`
  - `fix: resolve system beep in network boot scenario`
  - `docs: update build instructions for ARM architecture`
  - `refactor: optimize silence implementation`

#### Viewing Release Notes

Release notes are automatically attached to each GitHub release and can be found on the [releases page](https://github.com/Githubguy132010/Arch-Linux-without-the-beeps/releases).

---

### How to Trigger the GitHub Workflow

1. **Run the workflow**:
   You can run the workflow by going to **Actions > Build ISO** and clicking on **Run Workflow**. 

### Detailed Explanations of Each Workflow

#### Build ISO

- **File**: `build.yaml`
- **Purpose**: Builds the Arch Linux ISO.
- **Steps**:
  1. **Checkout Repository**: Pulls the latest files from the repository.
  2. **Set up Environment Variables**: Initializes necessary environment variables.
  3. **Set up Arch Linux Container**: Initializes the build environment.
  4. **Build ISO**: Builds the ISO using `mkarchiso`.
  5. **Generate Checksums**: Creates SHA256 and SHA512 checksums for the ISO.
  6. **Rename and Move ISO**: Renames the ISO file and moves it to the output directory.
  7. **Generate Release Notes**: Creates release notes for the new ISO.
  8. **Create Release**: Uploads the ISO and checksums as a new release on GitHub.

#### Check Dockerfile

- **File**: `dockerfile-check.yaml`
- **Purpose**: Ensures the Dockerfile works correctly.
- **Steps**:
  1. **Checkout Repository**: Pulls the latest files from the repository.
  2. **Build and Run Docker Container**: Builds the Docker image and runs the container to create the ISO.

### Setting Up and Configuring Dependabot

Dependabot can be used to automate dependency updates for GitHub Actions. Here's how to set it up:

1. **Create a `.github/dependabot.yml` file**:

   ```yaml
   version: 2
   updates:
     - package-ecosystem: "github-actions"
       directory: "/.github/workflows"
       schedule:
         interval: "daily"
       labels:
         - "github-actions"
       assignees:
         - "Githubguy132010"
   ```

2. **Commit and Push**: Commit the file to your repository and push the changes. Dependabot will now check for updates daily and create pull requests for any updates it finds.

### Monitoring and Troubleshooting GitHub Actions Workflows

1. **Monitor Workflow Runs**: Go to the **Actions** tab in your repository to see the status of workflow runs.
2. **View Logs**: Click on a workflow run to view detailed logs of each step.
3. **Troubleshoot Failures**:
   - **Check Logs**: Look for error messages in the logs to identify the cause of the failure.
   - **Rerun Jobs**: You can rerun failed jobs by clicking on the **Re-run jobs** button.
   - **Update Dependencies**: Ensure that all dependencies are up to date.

---

## Complete Silence: Disabling Firmware Beeps

While our customized Arch Linux ISO disables system beeps at the operating system level, some computers may still emit beeps from the firmware/BIOS during the Power-On Self Test (POST) process. These beeps are controlled by your computer's firmware settings and cannot be disabled by the operating system.

### Understanding Firmware vs. Operating System Beeps

- **Firmware/BIOS Beeps**: Generated during boot before the operating system loads; indicate hardware status
- **Operating System Beeps**: Generated by the OS after it has loaded; controlled by our customizations

### Accessing UEFI/BIOS Settings

To disable beeps at the firmware level, you'll need to access your computer's UEFI/BIOS settings:

1. **Restart your computer**
2. **Enter UEFI/BIOS setup** by pressing the appropriate key during boot:
   - Common keys include: F1, F2, F10, F12, Del, or Esc
   - The exact key varies by manufacturer (watch for on-screen prompts during boot)
   - On newer systems with fast boot enabled, you may need to access BIOS through your OS's restart options

### Common BIOS Beep Settings Locations

Beep settings are typically found under different menus depending on your manufacturer:

| Manufacturer | Common Menu Location                            | Setting Name                 |
|-------------|------------------------------------------------|------------------------------|
| Dell        | System Setup > POST Behavior                   | Keyboard Errors / Warnings   |
| HP          | Advanced > Device Options                      | Beep Codes / POST Messages   |
| Lenovo      | Config > Power > Beep and Alarm               | Power-On Beep / Keyboard Beep |
| ASUS        | Advanced > Onboard Devices Configuration       | System Beep                  |
| MSI         | Settings > Advanced > Integrated Peripherals   | Chassis Intrusion / USB Beep |
| Gigabyte    | BIOS > Advanced > Boot                        | Quiet Boot / Boot Beep       |
| Intel       | Advanced > Beep Options                        | Power-On Beep / Error Beep   |

### UEFI vs. Legacy BIOS Navigation

- **UEFI interfaces** typically have a graphical interface navigated with a mouse
- **Legacy BIOS interfaces** usually require keyboard navigation with arrow keys and Enter/Esc

### Common Beep-Related Settings

Look for settings with these or similar names:

- **System Beep** or **Power-On Beep**
- **POST Beep**
- **Audio Alert**
- **Quiet Boot**
- **Speaker** or **Internal Speaker**
- **Boot Up Beep**
- **Keyboard Beep** or **Keyboard Click**

### Manufacturer-Specific Notes

#### Dell Systems
Dell computers often have the beep settings under "POST Behavior" in System Setup. Look for "Keyboard Errors" or "Warnings and Errors" options.

#### HP Systems
HP BIOS typically places beep controls under "Advanced" > "Device Options" or "Built-In Device Options", with settings like "Beep Codes" or "Startup Sound".

#### Lenovo Systems
Lenovo systems usually have beep settings under "Config" > "Power" or "Config" > "Beep and Alarm" with options like "Power-On Beep".

#### ASUS Motherboards
ASUS motherboards typically have a "System Beep" option under "Advanced" > "Onboard Devices Configuration".

### After Disabling Firmware Beeps

After disabling beeps in your BIOS/UEFI settings:

1. **Save changes** and exit the BIOS/UEFI setup (usually F10 or a "Save & Exit" option)
2. **Boot into Arch Linux** (your system should now be completely silent)
3. Verify that both POST beeps and system beeps are disabled

### When BIOS Beep Disabling Is Not Available

Some systems don't provide options to disable firmware beeps. In these cases, you might consider:

- Physically disconnecting the internal speaker (for desktop computers)
- Using a headless configuration (no monitor) where supported
- Checking for BIOS updates that might add beep control options

---

## Troubleshooting Common Issues

### Network Problems

If you experience network issues during the build process, consider the following tips:

1. **Check Your Internet Connection**: Ensure that your internet connection is stable.
2. **Use a Different Network**: Try using a different network to see if the issue persists.
3. **Configure Docker Network Settings**: Adjust Docker's network settings if necessary.

### Common Build Errors

#### Package Not Found

If a package is not found during the build process, ensure that the package name is correct and that it exists in the Arch Linux repositories.

#### Duplicate Packages

If duplicate packages are found in the package list, remove the duplicates to resolve the issue.

---

## FAQ

### What is the purpose of this project?

This project provides a customized Arch Linux ISO with system beeps disabled, ideal for users who prefer a quieter environment.

### How often is the ISO updated?

The ISO is updated daily through an automated GitHub Actions workflow.

### How can I contribute to this project?

You can contribute by reporting issues, suggesting features, or submitting pull requests. Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file for more details.

### Where can I download the latest ISO?

You can download the latest ISO from the [releases page](https://github.com/Githubguy132010/Arch-Linux-without-the-beeps/releases).

---

## License

This project is licensed under my custom license - see the [LICENSE](LICENSE) file for details.

---
