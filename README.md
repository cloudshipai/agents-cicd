# DevOps Security CICD Demo

This repository demonstrates Station's agent bundle execution in CICD pipelines with comprehensive security scanning.

## Project Structure

- **Terraform**: AWS infrastructure with intentional security issues for testing
- **Docker**: Container configurations with various security concerns  
- **Python**: Application code with potential vulnerabilities
- **Scripts**: Automation and deployment scripts

## Security Scanning

This project uses Station agents with the following tools:
- **Terraform Security**: checkov, tflint for IaC security
- **Container Security**: trivy, dockle for container scanning
- **Code Security**: gitleaks, semgrep for secret/vulnerability detection

## CICD Integration

Station agents run automatically on:
- Pull requests for security analysis
- Main branch for compliance reporting
- Scheduled scans for continuous monitoring

## Installation

```bash
# Install Station bundle
stn template install https://your-registry/bundles/security-scanner-bundle.tar.gz

# Run security scan
stn agent call <agent-id> "Scan this repository for security issues"
```