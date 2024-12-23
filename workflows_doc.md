## 🔄 Automated Workflows

This project uses the following GitHub Actions workflows:

### Validate and Test Build

File: `build-check.yaml`

Triggered by:
- 🔘 Manual trigger
- ⏰ Scheduled: `0 0 * * *`
- 🔄 Pull request

### Build ISO

File: `build.yaml`

Triggered by:
- 🔘 Manual trigger
- ⏰ Scheduled: `0 0 * * *`
- 📤 Push to repository

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

