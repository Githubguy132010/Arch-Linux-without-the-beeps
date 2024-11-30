
---

# Arch Linux Without the Beeps

This repository provides a customized Arch Linux ISO with the system beeps disabled, ideal for users who prefer a quieter environment.

## Features

- **Silent Mode**: Disables systemd-boot and other system beeps for a quieter experience.
- **Arch Linux Base**: Utilizes the latest Arch Linux for a clean and minimal system.
- **Custom ISO**: Provides an easy way to build and download a custom ISO.
- **Automated Daily Builds**: Automatically generates and releases ISO builds daily using GitHub Actions.

## Table of Contents

- [Features](#features)
- [How to Build the ISO Locally](#how-to-build-the-iso-locally)
   - [Prerequisites](#prerequisites)
   - [Steps to Build Locally](#steps-to-build-locally)
- [How to Use GitHub Actions (Automated Workflow)](#how-to-use-github-actions-automated-workflow)
   - [How It Works](#how-it-works)
   - [GitHub Actions Workflow Overview](#github-actions-workflow-overview)
   - [How to Trigger the GitHub Workflow](#how-to-trigger-the-github-workflow)
- [License](#license)
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


---

## License

This project is licensed under my custom license - see the [LICENSE](LICENSE) file for details.
