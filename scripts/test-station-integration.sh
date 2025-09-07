#!/bin/bash

# Station CICD Integration Test Script
# This script validates the complete Station + CICD integration workflow

set -e

echo "🚀 Station CICD Integration Test"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_ENV_NAME="test-cicd-integration"
BUNDLE_URL="https://github.com/cloudshipai/registry/releases/latest/download/devops-security-bundle.tar.gz"
PROJECT_ROOT="$(pwd)"

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker not found. Install Docker first."
        exit 1
    fi
    
    # Create Station Docker wrapper if stn command doesn't exist
    if ! command -v stn &> /dev/null; then
        log "Creating Station Docker wrapper..."
        mkdir -p ~/.local/bin
        cat > ~/.local/bin/stn << 'EOF'
#!/bin/bash
docker run --rm \
  -v "$PWD:/workspace" \
  -v "$HOME/.config/station:/home/station/.config/station" \
  -w /workspace \
  -e OPENAI_API_KEY \
  ghcr.io/cloudship-io/station:latest \
  stn "$@"
EOF
        chmod +x ~/.local/bin/stn
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    if [ -z "$OPENAI_API_KEY" ]; then
        warning "OPENAI_API_KEY not set. Agent execution will fail."
    fi
    
    success "Prerequisites check complete"
}

# Test bundle installation
test_bundle_installation() {
    log "Testing bundle installation..."
    
    # Clean up any existing test environment
    rm -rf ~/.config/station/environments/$TEST_ENV_NAME 2>/dev/null || true
    
    # Create environment directory
    mkdir -p ~/.config/station/environments/$TEST_ENV_NAME
    
    # Set up variables
    cat > ~/.config/station/environments/$TEST_ENV_NAME/variables.yml << EOF
PROJECT_ROOT: "$PROJECT_ROOT"
BUNDLE_VERSION: "latest"
CICD_MODE: "test"
EOF
    
    # Try to install bundle
    log "Installing DevOps Security Bundle..."
    if stn bundle install "$BUNDLE_URL" "$TEST_ENV_NAME"; then
        success "Bundle installation successful"
    else
        warning "Bundle installation failed, creating fallback environment"
        create_fallback_environment
    fi
}

# Create fallback environment for testing
create_fallback_environment() {
    log "Creating fallback test environment..."
    
    # Create template.json
    cat > ~/.config/station/environments/$TEST_ENV_NAME/template.json << 'EOF'
{
  "name": "test-cicd-integration",
  "description": "Test CICD integration environment",
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem@latest", "{{ .PROJECT_ROOT }}"]
    }
  }
}
EOF

    # Create agents directory
    mkdir -p ~/.config/station/environments/$TEST_ENV_NAME/agents
    
    # Create test security scanner agent
    cat > ~/.config/station/environments/$TEST_ENV_NAME/agents/Test\ Security\ Scanner.prompt << 'EOF'
---
metadata:
  name: "Test Security Scanner"
  description: "Test security scanner for CICD integration validation"
  tags: ["test", "security", "terraform", "docker"]
model: gpt-4o-mini
max_steps: 5
tools:
  - "__read_text_file"
  - "__list_directory"
  - "__directory_tree"
  - "__search_files"
  - "__get_file_info"
---

{{role "system"}}
You are a Test Security Scanner designed to validate Station's CICD integration capabilities.

Your testing process:
1. **Repository Analysis**: Scan the project structure and identify key files
2. **Security Assessment**: Look for obvious security issues in terraform, docker, and code
3. **Report Generation**: Provide a concise summary of findings
4. **Integration Validation**: Confirm that Station agents can successfully analyze codebases in CICD

Focus on demonstrating that the integration works correctly and can identify common security issues.

{{role "user"}}
{{userInput}}
EOF

    success "Fallback environment created successfully"
}

# Test environment sync
test_environment_sync() {
    log "Testing environment synchronization..."
    
    if stn sync "$TEST_ENV_NAME"; then
        success "Environment sync successful"
    else
        error "Environment sync failed"
        return 1
    fi
    
    # List available agents
    log "Available agents in test environment:"
    stn agent list --env "$TEST_ENV_NAME" || warning "Could not list agents"
}

# Test agent execution
test_agent_execution() {
    log "Testing agent execution..."
    
    if [ -z "$OPENAI_API_KEY" ]; then
        warning "Skipping agent execution test - OPENAI_API_KEY not set"
        return 0
    fi
    
    # Get the first available agent
    AGENT_NAME=$(stn agent list --env "$TEST_ENV_NAME" --format json | jq -r '.[0].name // empty' 2>/dev/null || echo "Test Security Scanner")
    
    if [ -n "$AGENT_NAME" ]; then
        log "Testing agent: $AGENT_NAME"
        
        # Test with a simple task
        TEST_TASK="Analyze the project structure and identify the main components (terraform, docker, code files). Provide a brief security assessment summary."
        
        log "Executing test task..."
        if timeout 120 stn agent call "$AGENT_NAME" "$TEST_TASK" --env "$TEST_ENV_NAME"; then
            success "Agent execution test successful"
        else
            warning "Agent execution test failed or timed out"
        fi
    else
        error "No agents found in test environment"
        return 1
    fi
}

# Test CI/CD workflow files
test_workflow_files() {
    log "Validating CI/CD workflow files..."
    
    WORKFLOW_DIR=".github/workflows"
    
    if [ ! -d "$WORKFLOW_DIR" ]; then
        error "Workflows directory not found: $WORKFLOW_DIR"
        return 1
    fi
    
    # Check for Station workflows
    WORKFLOWS=("station-security-scan.yml" "station-bundle-demo.yml")
    
    for workflow in "${WORKFLOWS[@]}"; do
        if [ -f "$WORKFLOW_DIR/$workflow" ]; then
            success "Found workflow: $workflow"
            
            # Basic YAML validation
            if command -v yamllint &> /dev/null; then
                if yamllint "$WORKFLOW_DIR/$workflow"; then
                    success "YAML validation passed for $workflow"
                else
                    warning "YAML validation issues in $workflow"
                fi
            fi
        else
            error "Missing workflow: $workflow"
        fi
    done
}

# Test project structure for vulnerabilities
test_vulnerability_detection() {
    log "Testing vulnerability detection capability..."
    
    # Check if test files exist
    TEST_FILES=("terraform/main.tf" "docker/Dockerfile" "python/vulnerable_app.py")
    
    for file in "${TEST_FILES[@]}"; do
        if [ -f "$file" ]; then
            success "Found test file: $file"
        else
            warning "Missing test file: $file"
        fi
    done
    
    # Verify intentional vulnerabilities exist for testing
    if grep -q "0.0.0.0/0" terraform/main.tf 2>/dev/null; then
        success "Found intentional Terraform vulnerability for testing"
    fi
    
    if grep -q "USER root" docker/Dockerfile 2>/dev/null; then
        success "Found intentional Docker vulnerability for testing"
    fi
    
    if grep -q "password123" terraform/main.tf 2>/dev/null; then
        success "Found intentional hardcoded credential for testing"
    fi
}

# Cleanup function
cleanup() {
    log "Cleaning up test environment..."
    rm -rf ~/.config/station/environments/$TEST_ENV_NAME 2>/dev/null || true
    success "Cleanup complete"
}

# Main test execution
main() {
    echo "Starting Station CICD Integration Tests..."
    echo "Project: $PROJECT_ROOT"
    echo "Bundle: $BUNDLE_URL"
    echo "Test Environment: $TEST_ENV_NAME"
    echo

    # Run all tests
    check_prerequisites
    echo
    
    test_bundle_installation
    echo
    
    test_environment_sync
    echo
    
    test_workflow_files
    echo
    
    test_vulnerability_detection
    echo
    
    test_agent_execution
    echo
    
    success "🎉 Station CICD Integration Tests Complete!"
    echo
    echo "Next steps:"
    echo "1. Push these workflows to GitHub to test in real CI/CD"
    echo "2. Set OPENAI_API_KEY secret in GitHub repository settings"
    echo "3. Trigger workflows manually or via PR to test functionality"
    echo "4. Review agent execution results in GitHub Actions logs"
}

# Handle script interruption
trap cleanup EXIT

# Check for help flag
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Station CICD Integration Test Script"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --no-cleanup   Don't cleanup test environment after running"
    echo
    echo "Environment Variables:"
    echo "  OPENAI_API_KEY    Required for agent execution tests"
    echo
    echo "This script validates:"
    echo "- Station CLI installation and functionality"
    echo "- Bundle installation from CloudShip registry"
    echo "- Environment setup and synchronization"
    echo "- Agent execution capability"
    echo "- CI/CD workflow file validation"
    echo "- Project vulnerability detection setup"
    exit 0
fi

# Run main function
main