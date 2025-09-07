# Zero to Hero Lab: Building Distributed DevOps Intelligence with Station

## Overview

This lab takes you from **zero Kubernetes experience** to **production-ready containerized applications** with **Station agents providing intelligent decision support** at every stage.

We'll build progressively more complex infrastructure while creating Station agents that provide contextual intelligence using MCP tools you wouldn't want directly in Claude Code.

## Lab Structure

Each stage includes:
- **Practical implementation** (Flask app, Node.js app, infrastructure)
- **Station agent creation** for that stage's challenges  
- **Documentation** of what we learned
- **Bundle creation** stored in git LFS for reuse

## Stage Progression

### **Stage 1: Local Development Foundation**
**Goal**: Build simple applications locally with Station agents for learning support

**What You'll Build**:
- Simple Flask API (Python backend)
- Simple Node.js frontend (React/Express)
- Docker containers for both
- Station agents for Docker best practices

**Station Agents**:
- **Dockerfile Tutor**: Real-time feedback on container best practices
- **Security Mentor**: Catch security issues as you write code
- **Performance Guide**: Optimization recommendations

**MCP Tools**: Docker inspection, security scanning, performance analysis
**Bundle**: `local-development-bundle.tar.gz`

---

### **Stage 2: Container Orchestration Introduction**
**Goal**: Move from Docker Compose to Kubernetes basics

**What You'll Build**:
- Docker Compose setup for Flask + Node.js + Redis
- Basic Kubernetes manifests (Deployments, Services, ConfigMaps)
- Local Kubernetes cluster (kind/minikube)
- Station agents for K8s learning

**Station Agents**:
- **Kubernetes Tutor**: Explains K8s concepts as you write manifests
- **Resource Optimizer**: Right-sizing recommendations for containers
- **Health Check Advisor**: Proper liveness/readiness probe guidance

**MCP Tools**: kubectl, k8s API, resource monitoring, manifest validation
**Bundle**: `kubernetes-basics-bundle.tar.gz`

---

### **Stage 3: CI/CD Pipeline Intelligence**
**Goal**: Build GitHub Actions with intelligent quality gates

**What You'll Build**:
- GitHub Actions workflows for both applications
- Multi-stage builds, testing, security scanning
- Container registry pushes
- Station agents for pipeline optimization

**Station Agents**:
- **Build Optimizer**: Analyze build times and suggest improvements
- **Security Gate**: Intelligent security finding prioritization  
- **Deployment Advisor**: Should this change be deployed now?

**MCP Tools**: GitHub API, container scanning, test analysis, deployment metrics
**Bundle**: `cicd-intelligence-bundle.tar.gz`

---

### **Stage 4: Infrastructure as Code** 
**Goal**: Deploy to cloud with Terraform and intelligent infrastructure decisions

**What You'll Build**:
- AWS EKS cluster with Terraform
- RDS database, Load balancers, VPCs
- Terraform modules and best practices
- Station agents for infrastructure intelligence

**Station Agents**:
- **Infrastructure Advisor**: Cost vs performance trade-offs
- **Security Auditor**: Infrastructure security validation
- **Compliance Monitor**: Regulatory requirement checking

**MCP Tools**: Terraform, AWS CLI, Checkov, TFLint, cost analysis
**Bundle**: `infrastructure-intelligence-bundle.tar.gz`

---

### **Stage 5: Production Operations**
**Goal**: Full production setup with monitoring, logging, and operational intelligence

**What You'll Build**:
- Prometheus + Grafana monitoring
- ELK stack for logging  
- Alert manager configuration
- Station agents for operational excellence

**Station Agents**:
- **Incident Responder**: Correlate alerts with recent changes
- **Performance Monitor**: Continuous optimization recommendations
- **Cost Controller**: Automated cost optimization suggestions

**MCP Tools**: Prometheus, Grafana, ELK, PagerDuty, cost APIs, performance profiling
**Bundle**: `production-operations-bundle.tar.gz`

---

### **Stage 6: Advanced Patterns**
**Goal**: Service mesh, advanced deployments, and intelligent automation

**What You'll Build**:
- Istio service mesh
- Blue/green deployments
- Chaos engineering experiments
- Station agents for advanced operations

**Station Agents**:
- **Deployment Strategist**: Choose optimal deployment patterns
- **Chaos Engineer**: Intelligent failure injection and analysis
- **Service Mesh Optimizer**: Traffic management and security policies

**MCP Tools**: Istio CLI, chaos tools, advanced monitoring, traffic analysis
**Bundle**: `advanced-patterns-bundle.tar.gz`

## Repository Structure

```
agents-cicd/
├── STATION_VISION.md
├── ZERO_TO_HERO_LAB.md
├── applications/
│   ├── flask-api/          # Python Flask backend
│   ├── nodejs-frontend/    # Node.js React frontend
│   └── shared/            # Shared configs, databases
├── infrastructure/
│   ├── docker/            # Docker Compose setups
│   ├── kubernetes/        # K8s manifests by stage
│   ├── terraform/         # Infrastructure as Code
│   └── monitoring/        # Observability configs
├── station-agents/
│   ├── stage1-local/      # Local development agents
│   ├── stage2-k8s/        # Kubernetes learning agents
│   ├── stage3-cicd/       # Pipeline intelligence agents
│   ├── stage4-infra/      # Infrastructure agents
│   ├── stage5-prod/       # Production operations agents
│   └── stage6-advanced/   # Advanced pattern agents
├── bundles/              # Git LFS stored bundles
│   ├── local-development-bundle.tar.gz
│   ├── kubernetes-basics-bundle.tar.gz
│   ├── cicd-intelligence-bundle.tar.gz
│   ├── infrastructure-intelligence-bundle.tar.gz
│   ├── production-operations-bundle.tar.gz
│   └── advanced-patterns-bundle.tar.gz
└── lab-notes/           # Documentation for each stage
    ├── stage1-notes.md
    ├── stage2-notes.md
    ├── stage3-notes.md
    ├── stage4-notes.md
    ├── stage5-notes.md
    └── stage6-notes.md
```

## Stage 1: Let's Start Building

**Ready to begin?** Let's start with Stage 1 - building simple applications locally with Station agents that provide learning support for Docker and containerization best practices.

This will demonstrate:
- **Local Mode**: Station agents as Claude Code sub-agents
- **Real-time Learning**: Agents that teach Docker best practices
- **MCP Tool Integration**: Using container analysis tools you wouldn't want directly in Claude
- **Progressive Complexity**: Start simple, build confidence

**Next**: Create the Flask API application with intentional room for improvement so our Station agents can provide meaningful guidance.

Shall we start building the Stage 1 applications and agents?