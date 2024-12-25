## 🔄 Automated Workflows

This project uses the following GitHub Actions workflows:

### Build ISO

File: `build-and-release.yaml`

Triggered by:
- 🔘 Manual trigger
- ⏰ Scheduled: `0 0 * * *`
- 📤 Push to repository

### Build Arch Linux ISO

File: `build-and-save.yaml`

Triggered by:
- 🔘 Manual trigger
- ⏰ Scheduled: `0 0 * * *`

### Validate and Test Build

File: `build-check.yaml`

Triggered by:
- 🔘 Manual trigger
- ⏰ Scheduled: `0 0 * * *`
- 🔄 Pull request

### Create Release

File: `create-release.yaml`

Triggered by:
- 🔘 Manual trigger

### Check to make sure Dockerfile works

File: `dockerfile-check.yaml`

Triggered by:
- 🔘 Manual trigger
- ⏰ Scheduled: ``
- 🔄 Pull request

### Update Documentation

File: `update-docs.yaml`

Triggered by:
- 🔘 Manual trigger
- ⏰ Scheduled: `" -f2)`
- 📤 Push to repository
- 🔄 Pull request

### Update Packages

File: `update-packages.yaml`

Triggered by:
- 🔘 Manual trigger
- ⏰ Scheduled: `0 2 * * *`

