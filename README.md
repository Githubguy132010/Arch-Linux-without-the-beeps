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

1. **Run the workflow**:
   You can run the workflow by going to **Actions > Build ISO** and clicking on **Run Workflow**. 

### Detailed Explanations of Each Workflow

#### Build ISO

- **File**: `build.yaml`
- **Purpose**: Builds the Arch Linux ISO.
- **Steps**:
  1. **Checkout Repository**: Pulls the latest files from the repository.
  2. **Set up Environment Variables**: Initializes necessary environment variables.
  3. **Cache Pacman Packages**: Caches packages to speed up the build process.
  4. **Set up Arch Linux Container**: Initializes the build environment.
  5. **Build ISO**: Builds the ISO using `mkarchiso`.
  6. **Generate Checksums**: Creates SHA256 and SHA512 checksums for the ISO.
  7. **Rename and Move ISO**: Renames the ISO file and moves it to the output directory.
  8. **Generate Release Notes**: Creates release notes for the new ISO.
  9. **Create Release**: Uploads the ISO and checksums as a new release on GitHub.

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

## Troubleshooting Common Issues

### Docker Permission Errors

If you encounter permission errors when running Docker commands, try the following solutions:

1. **Add Your User to the Docker Group**:

   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **Run Docker Commands with `sudo`**:

   ```bash
   sudo docker run ...
   ```

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

## Setting Up the Development Environment

To set up the development environment, follow these steps:
1. **Clone the repository**: Start by cloning the repository to your local machine.

   ```bash
   git clone https://github.com/Githubguy132010/Arch-Linux-without-the-beeps.git
   cd Arch-Linux-without-the-beeps
   ```

2. **Install Docker**: Ensure Docker is installed on your system. Docker is used to create a containerized environment for building the ISO.

3. **Build the Docker image**: Build the Docker image that will be used to build the ISO.

   ```bash
   docker build -t arch-iso-builder .
   ```

4. **Run the Docker container**: Use the Docker image to run a container and build the ISO.

   ```bash
   docker run --rm --privileged -v $(pwd):/workdir arch-iso-builder bash -c "mkarchiso -v -w workdir/ -o out/ ."
   ```

5. **Retrieve the ISO**: After the build process completes, the ISO will be available in the `out/` directory within your local folder as `Arch.iso`.

6. **Set up GitHub Actions**: If you want to use GitHub Actions for automated builds, ensure the workflows in `.github/workflows/` are correctly configured. The `.github/workflows/build.yaml` and `.github/workflows/build-check.yaml` files provide the necessary steps for building and verifying the ISO.

7. **Follow contribution guidelines**: Refer to the `CONTRIBUTING.md` file for detailed instructions on how to contribute to the project, including reporting bugs, submitting fixes, and proposing new features.

8. **Refer to the README**: The `README.md` file provides detailed steps for building the ISO locally and using GitHub Actions. It also includes troubleshooting information for common issues.

---

## Additional Resources for New Contributors

Here are some additional resources and links that can help new contributors get started:

- [Arch Linux Wiki](https://wiki.archlinux.org/): Comprehensive documentation and guides for Arch Linux.
- [Docker Documentation](https://docs.docker.com/): Official Docker documentation and tutorials.
- [GitHub Actions Documentation](https://docs.github.com/en/actions): Official GitHub Actions documentation and guides.
- [Arch Linux Forums](https://bbs.archlinux.org/): Community forums for Arch Linux users and developers.
- [GitHub Guides](https://guides.github.com/): Guides and tutorials for using GitHub effectively.

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
