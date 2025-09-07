# Station CICD Integration Guide

This repository demonstrates how to integrate Station AI agents into your CI/CD pipelines for automated security scanning and code analysis.

## Quick Start

### 1. Set Up GitHub Repository

Add the following secret to your GitHub repository:
- `OPENAI_API_KEY`: Your OpenAI API key for agent execution

### 2. Install Workflows

The `.github/workflows/` directory contains two main workflows:

#### Station Security Scan (`station-security-scan.yml`)
- **Triggers**: Push to main/develop, Pull Requests, Daily at 2 AM UTC
- **Purpose**: Automated security scanning using Station agents
- **Bundle**: Installs DevOps Security Bundle from CloudShip registry
- **Analysis**: Terraform, Docker, and code security scanning

#### Station Bundle Demo (`station-bundle-demo.yml`)  
- **Triggers**: Manual dispatch with custom parameters
- **Purpose**: Demonstrates bundle installation and agent execution
- **Configurable**: Bundle URL and task can be customized
- **Testing**: Validates complete Station integration workflow

### 3. Local Testing

Run the integration test script to validate your setup:

```bash
# Set your OpenAI API key
export OPENAI_API_KEY="your-api-key-here"

# Run the test script
./scripts/test-station-integration.sh
```

## Workflow Details

### Station Security Scan Workflow

This workflow performs comprehensive security analysis:

1. **Environment Setup**
   - Installs Station CLI
   - Creates environment with PROJECT_ROOT variable
   - Installs DevOps Security Bundle from registry

2. **Security Analysis**
   - **Terraform Security**: Scans for misconfigurations, public access, hardcoded secrets
   - **Container Security**: Analyzes Docker files for vulnerabilities and best practices
   - **Code Security**: Detects secrets, vulnerabilities, and security issues

3. **Reporting**
   - Generates GitHub Actions summary with findings
   - Comments on Pull Requests with security analysis
   - Uploads security artifacts for review

### Bundle Demo Workflow

Manual workflow for testing different bundles:

1. **Bundle Installation**
   - Downloads bundle from specified URL (default: CloudShip registry)
   - Installs in temporary environment
   - Sets up variables for bundle execution

2. **Agent Execution** 
   - Lists available agents from bundle
   - Executes agents with custom tasks
   - Demonstrates specialized agent capabilities

3. **Validation**
   - Tests terraform auditing agents
   - Tests container scanning agents  
   - Validates complete integration workflow

## Bundle Registry

Station bundles are hosted in the CloudShip registry:

**DevOps Security Bundle**: `https://github.com/cloudshipai/registry/releases/latest/download/devops-security-bundle.tar.gz`

This bundle includes:
- **Terraform Security Auditor**: Infrastructure security analysis
- **Container Security Scanner**: Docker security best practices
- **Code Vulnerability Detector**: Application security scanning
- **Compliance Auditor**: Security framework compliance checking

## Integration Commands

### Install Bundle
```bash
stn bundle install https://github.com/cloudshipai/registry/releases/latest/download/devops-security-bundle.tar.gz production
```

### Setup Environment
```bash
# Create variables file
echo "PROJECT_ROOT: $(pwd)" > ~/.config/station/environments/production/variables.yml

# Sync environment
stn sync production
```

### Execute Agents
```bash
# List available agents
stn agent list --env production

# Run security scan
stn agent call "Terraform Security Auditor" "Scan the terraform directory for security issues" --env production
```

## Customization

### Adding Custom Agents

1. Create agent prompt file in environment:
```bash
~/.config/station/environments/your-env/agents/Your-Agent.prompt
```

2. Define agent metadata and capabilities:
```yaml
---
metadata:
  name: "Your Custom Agent"
  description: "Agent description"
  tags: ["security", "custom"]
model: gpt-4o-mini
max_steps: 8
tools:
  - "__read_text_file"
  - "__list_directory"
---
```

3. Sync and test:
```bash
stn sync your-env
stn agent call "Your Custom Agent" "Test task" --env your-env
```

### Custom Workflows

Copy and modify the example workflows:

1. **station-security-scan.yml**: For automated security scanning
2. **station-bundle-demo.yml**: For custom bundle testing

Customize:
- Trigger conditions (branches, schedules)
- Bundle URLs and agent tasks
- Environment variables and secrets
- Reporting and notification settings

## Troubleshooting

### Common Issues

**Bundle Installation Fails**
- Check bundle URL accessibility
- Verify network connectivity in CI/CD environment
- Ensure Station CLI is properly installed

**Agent Execution Fails**
- Verify OPENAI_API_KEY is set correctly
- Check agent exists in environment (`stn agent list`)
- Validate environment sync completed successfully

**Environment Sync Issues**
- Check template.json syntax
- Verify variables.yml format
- Ensure MCP server dependencies are available

### Debug Commands

```bash
# Check Station status
stn --version
stn config info

# List environments
stn env list

# Check environment configuration
stn sync your-env --dry-run

# View agent runs
stn runs list --env your-env
stn runs inspect <run-id> --verbose
```

## Security Best Practices

1. **API Key Management**
   - Store OPENAI_API_KEY as GitHub secret
   - Never commit API keys to repository
   - Use environment-specific keys for different stages

2. **Bundle Verification**
   - Only install bundles from trusted sources
   - Review bundle contents before deployment
   - Use versioned bundle URLs for reproducibility

3. **Access Control**
   - Limit workflow permissions to minimum required
   - Use read-only tokens where possible
   - Monitor agent execution logs for anomalies

4. **Data Security**
   - Agent analysis stays within CI/CD environment
   - No sensitive data is sent to external services
   - Artifacts are automatically cleaned up

## Next Steps

1. **Deploy to Production**: Merge workflows to main branch
2. **Monitor Results**: Review security scan results in GitHub Actions
3. **Customize Agents**: Create specialized agents for your stack
4. **Scale Integration**: Add Station agents to more repositories
5. **Bundle Development**: Create custom bundles for your organization

## Support

- **Station Documentation**: [Station Docs](https://station.dev/docs)
- **CloudShip Registry**: [Registry](https://github.com/cloudshipai/registry)
- **Issues**: Report issues in respective GitHub repositories
- **Community**: Join Station community for support and discussions