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

## Setting Up the Development Environment

To set up the development environment for this project, follow these steps:

1. **Ensure you have Docker installed on your system**. Refer to the instructions in the `README.md` for Docker installation on different operating systems.
2. **Clone the repository**:
   ```bash
   git clone https://github.com/Githubguy132010/Arch-Linux-without-the-beeps.git
   cd Arch-Linux-without-the-beeps
   ```
3. **Build the Docker image**:
   ```bash
   docker build -t arch-iso-builder .
   ```
4. **Run the Docker container to build the ISO**:
   ```bash
   docker run --rm --privileged -v $(pwd):/workdir arch-iso-builder bash -c "mkarchiso -v -w workdir/ -o out/ ."
   ```
5. **Retrieve the ISO from the `out/` directory in your local folder**.

For more detailed instructions, refer to the `README.md` file. If you encounter any issues, check the troubleshooting section in the same file.

---

## Additional Resources for New Contributors

To help new contributors get started with the project, the following additional resources are available:

- **Detailed setup instructions**: Ensure the `README.md` file includes comprehensive steps for setting up the development environment, including Docker installation and common troubleshooting tips.
- **Contribution guidelines**: Expand the `CONTRIBUTING.md` file to include more specific details on testing, documentation updates, and coding standards.
- **Code of conduct**: Add a `CODE_OF_CONDUCT.md` file to outline the expected behavior and guidelines for contributors.
- **Issue and pull request templates**: Ensure the `.github/ISSUE_TEMPLATE/` directory contains templates for bug reports and feature requests to standardize submissions.
- **Security policy**: Include a `SECURITY.md` file to provide guidelines on reporting vulnerabilities and the project's security measures.
- **Additional resources**: Provide links to relevant documentation, tutorials, and other resources that can help contributors learn more about the project and its dependencies.
