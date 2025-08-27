# 🚀 GitHub Setup for Station Security Audit

## 🔑 Setting Up Secrets

### Step 1: Add OpenAI API Key
1. Go to your GitHub repository: https://github.com/cloudshipai/agents-cicd
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **"New repository secret"**
5. Add:
   - **Name**: `OPENAI_API_KEY`
   - **Secret**: Your actual OpenAI API key (starts with `sk-`)

## 🎯 How to Run

### Manual Trigger (Recommended First)
1. Go to **Actions** tab in your repository
2. Click **"🛡️ Station DevOps Security Audit"** workflow
3. Click **"Run workflow"** button
4. Leave environment as `devops-simple` (default)
5. Click **"Run workflow"**

### Automatic Trigger
- The workflow automatically runs on all Pull Requests to `main`
- Results are posted as PR comments with detailed findings

## 📊 What You'll Get

### 1. **Detailed Agent Results** 📋
```
📋 Execution Results
Run ID: 1
Status: completed
Started: 2025-08-27T20:49:50Z
Completed: 2025-08-27T20:50:11Z (took 21.728626289s)

Result: [Full security analysis with findings]
Token Usage: Input tokens: 255, Output tokens: 511
```

### 2. **PR Comments** 💬
- Automatic detailed security analysis posted to PRs
- Security Scanner results with secret detection
- Terraform Auditor results with infrastructure security
- Actionable remediation steps

### 3. **GitHub Actions Summary** 📊
- High-level execution summary
- Tool usage statistics  
- Links to detailed results

### 4. **Downloadable Artifacts** 📁
- `results.log` - Full execution logs
- `security-results.txt` - Security scan details
- `terraform-results.txt` - Terraform audit details
- Individual analysis files

## 🛠️ Tools Included

### Security Scanner (4 tools)
- `gitleaks` for secret detection
- Filesystem access for code analysis

### Terraform Auditor (10 tools) 
- `checkov` for infrastructure security scanning
- Terraform best practices validation

**Total: 28 focused security tools**

## 🎉 Ready to Go!

Just add your `OPENAI_API_KEY` secret and run the workflow manually first to test it out!