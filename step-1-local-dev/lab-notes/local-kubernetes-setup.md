# Local Kubernetes Setup: K3s vs Alternatives

## **Recommended: K3s** ⭐

K3s is perfect for our zero-to-hero lab because:

### **Why K3s?**
- **Lightweight**: Uses ~512MB RAM vs 2GB+ for standard Kubernetes
- **Single Binary**: Easy installation, no complex setup
- **Production-like**: Real Kubernetes, not a simulation
- **Fast Startup**: Cluster ready in seconds
- **Container Registry**: Built-in local registry
- **LoadBalancer**: Includes Traefik ingress controller
- **Storage**: Built-in local-path storage provisioner

### **Installation**
```bash
# Install K3s (creates single-node cluster)
curl -sfL https://get.k3s.io | sh -

# Check status
sudo systemctl status k3s

# Get kubeconfig
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
```

### **Verification**
```bash
# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -A

# Check services
kubectl get svc -A
```

## **Alternative Options**

### **Docker Desktop Kubernetes**
- ✅ Easy if you already have Docker Desktop
- ❌ Resource heavy (2GB+ RAM)
- ❌ MacOS/Windows focused

### **kind (Kubernetes in Docker)**
```bash
# Install kind
go install sigs.k8s.io/kind@latest
# or
brew install kind

# Create cluster
kind create cluster --name station-lab
```
- ✅ Good for testing
- ❌ Nested Docker complexity
- ❌ More resource overhead

### **minikube**
```bash
# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start
```
- ✅ Feature complete
- ❌ VM overhead
- ❌ Slower startup

### **k0s**
```bash
# Download and install k0s
curl -sSLf https://get.k0s.sh | sudo sh
sudo k0s server --single
```
- ✅ Very lightweight
- ❌ Less ecosystem support than K3s

## **For Our Lab: K3s Setup**

### **Why K3s Wins for Station Lab:**
1. **Resource Efficient**: Won't compete with Station agents for resources
2. **Real Kubernetes**: Agents will work in production Kubernetes too  
3. **Fast Iteration**: Quick cluster restarts during development
4. **Built-in Services**: Traefik, CoreDNS, local storage all included
5. **No Docker-in-Docker**: Avoids container complexity

### **Post-Installation Setup**
```bash
# Install kubectl (if not already installed)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/

# Verify cluster
kubectl cluster-info

# Check available storage classes
kubectl get storageclass

# Test with a simple pod
kubectl run test --image=nginx --rm -it -- bash
```

### **Uninstall (if needed)**
```bash
# Stop K3s
sudo systemctl stop k3s

# Uninstall
/usr/local/bin/k3s-uninstall.sh
```

## **Next Steps for Stage 2**
Once K3s is installed, we'll create:
- Kubernetes manifests for Flask API and Node.js frontend
- Station agents that help with K8s best practices
- Progressive complexity from Deployments to Services to Ingress

The K3s cluster will be the foundation for Stages 2-6 of our lab.