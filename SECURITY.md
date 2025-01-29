# Security Policy

## Supported Versions

This project provides ISO builds of Arch Linux. We maintain and provide security updates for:

| Version | Supported          |
| ------- | ------------------ |
| Latest Release   | :white_check_mark: |
| Older Releases  | :x:                |

## Reporting a Vulnerability

We take the security of this project seriously. If you believe you have found a security vulnerability, please follow these steps:

1. **Do Not** open a public issue on GitHub
2. Send a description of the vulnerability to thomas.brugman.teb3@gmail.com
3. Include the following information:
   - Type of issue
   - Full paths of source file(s) related to the issue
   - The location of the affected source code
   - Any special configuration required to reproduce the issue
   - Step-by-step instructions to reproduce the issue
   - Proof-of-concept or exploit code (if possible)
   - Impact of the issue, including how an attacker might exploit it

## Security Measures

Our ISO builds implement several security measures:

1. **Verification**: All ISOs are provided with SHA256 checksums
2. **Updates**: The ISO is rebuilt daily with the latest security updates
3. **Minimal Surface**: Only essential packages are included
4. **Docker Security**: The build process runs in an isolated container

## Best Practices

When using this ISO:

1. Always verify the ISO checksum before installation
2. Keep your system updated regularly
3. Follow Arch Linux security guidelines
4. Implement appropriate system hardening measures

## Security Updates

- Security updates are handled through the standard Arch Linux package management system
- Critical security issues will be addressed as soon as possible
- Updates that affect the ISO build process will trigger a new build automatically
