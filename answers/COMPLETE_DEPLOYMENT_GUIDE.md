# Complete Step-by-Step Deployment Guide for Retail Store Application

## Table of Contents
1. [Prerequisites & Setup](#1-prerequisites--setup)
2. [Understanding the Architecture](#2-understanding-the-architecture)
3. [Local Development Setup](#3-local-development-setup)
4. [AWS Infrastructure Deployment](#4-aws-infrastructure-deployment)
5. [Kubernetes Cluster Setup](#5-kubernetes-cluster-setup)
6. [GitOps with ArgoCD](#6-gitops-with-argocd)
7. [Monitoring & Observability](#7-monitoring--observability)
8. [Security Hardening](#8-security-hardening)
9. [Service Mesh with Istio](#9-service-mesh-with-istio)
10. [Progressive Delivery](#10-progressive-delivery)
11. [Chaos Engineering](#11-chaos-engineering)
12. [Disaster Recovery](#12-disaster-recovery)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Prerequisites & Setup

### 1.1 What You Need to Install

Before we begin, let's understand **why** we need each tool:

| Tool | Purpose | Why We Need It |
|------|---------|----------------|
| AWS CLI | Command line interface for AWS | To interact with AWS services (create clusters, manage resources) |
| kubectl | Kubernetes command-line tool | To deploy applications, inspect and manage cluster resources |
| Terraform | Infrastructure as Code tool | To provision AWS infrastructure in a repeatable, version-controlled way |
| Docker | Container runtime | To build and run containerized applications locally |
| Helm | Kubernetes package manager | To install complex applications with a single command |
| Git | Version control | To clone repositories and enable GitOps workflows |

### 1.2 Installing AWS CLI

**What is AWS CLI?**
The AWS Command Line Interface (CLI) is a unified tool to manage your AWS services. With just one tool to download and configure, you can control multiple AWS services from the command line and automate them through scripts.

```bash
# For macOS using Homebrew
# Homebrew is a package manager for macOS that simplifies software installation
brew install awscli

# For Linux
# We download the installer zip file, unzip it, and run the install script
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
# The --version flag shows us the installed version to confirm it works
aws --version
```

### 1.3 Configuring AWS CLI

**Why do we configure AWS CLI?**
AWS needs to know who you are (authentication) and where you want to create resources (region). This configuration creates credentials that AWS services will use to verify your identity.

```bash
# This command opens an interactive configuration session
aws configure

# You will be prompted for:
# 1. AWS Access Key ID - This is like your username for AWS API
# 2. AWS Secret Access Key - This is like your password for AWS API
# 3. Default region name - Where your resources will be created (e.g., us-west-2)
# 4. Default output format - How you want responses (json, text, or table)

# Why us-west-2 (Oregon)?
# - Lower cost than some regions
# - Good availability of all AWS services
# - Multiple availability zones for high availability
```

**Where to get AWS credentials:**
1. Log into AWS Console (https://console.aws.amazon.com)
2. Go to IAM (Identity and Access Management)
3. Click "Users" → Your username → "Security credentials"
4. Click "Create access key"
5. Download and save securely (you only see the secret key once!)

### 1.4 Installing kubectl

**What is kubectl?**
Kubectl is the command-line tool for interacting with Kubernetes clusters. It allows you to deploy applications, inspect and manage cluster resources, and view logs.

```bash
# For macOS using Homebrew
brew install kubectl

# Alternative: Download directly from Kubernetes official releases
# The -L flag follows redirects, -o specifies output file
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/darwin/amd64/kubectl"
chmod +x kubectl  # Make it executable
sudo mv kubectl /usr/local/bin/  # Move to PATH

# Verify installation
kubectl version --client

# What does the output mean?
# - Client Version: The version of kubectl you installed
# - Kustomize Version: Built-in tool for customizing Kubernetes configs
```

### 1.5 Installing Terraform

**What is Terraform?**
Terraform is an Infrastructure as Code (IaC) tool that allows you to define infrastructure in configuration files that can be versioned, reused, and shared. Instead of clicking around the AWS console, you write code to create resources.

```bash
# For macOS using Homebrew
brew install terraform

# For Linux
# Download the binary directly from HashiCorp
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version

# Enable tab completion (optional but helpful)
# This lets you press Tab to auto-complete terraform commands
complete -C /usr/local/bin/terraform terraform
```

### 1.6 Installing Helm

**What is Helm?**
Helm is a package manager for Kubernetes. Think of it like npm for Node.js or pip for Python. It packages all the Kubernetes manifests (YAML files) needed to run an application into a single unit called a "chart."

```bash
# For macOS using Homebrew
brew install helm

# For Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version

# Add common Helm repositories
# Repositories are like app stores - they contain charts you can install
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update  # Get the latest chart information
```

### 1.7 Installing Docker

**What is Docker?**
Docker is a platform for developing, shipping, and running applications in containers. Containers package an application with all its dependencies, ensuring it runs the same way everywhere.

```bash
# For macOS: Download Docker Desktop from https://www.docker.com/products/docker-desktop
# The Docker Desktop application installs both Docker Engine and Docker CLI

# For Linux (Ubuntu):
# Update the package index
sudo apt-get update

# Install Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io

# Add your user to the docker group (so you don't need sudo)
sudo usermod -aG docker $USER

# Verify installation
docker --version

# Test that Docker is running
docker run hello-world

# This command downloads a test image and runs it in a container
# If successful, you'll see a message "Hello from Docker!"
```

### 1.8 Installing Git

**What is Git?**
Git is a distributed version control system. It tracks changes in your code and allows multiple people to work on the same project simultaneously.

```bash
# For macOS (should be pre-installed, but if not)
brew install git

# For Linux
sudo apt-get install git  # Ubuntu/Debian
sudo yum install git      # CentOS/RHEL

# Verify installation
git --version

# Configure your identity (Git uses this to track who made changes)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## 2. Understanding the Architecture

### 2.1 Why This Architecture?

**Microservices Architecture:**
Instead of building one giant application (monolith), we break it into smaller, independent services. Each service:
- Has its own database (data ownership)
- Can be deployed independently
- Can be scaled independently
- Has a single responsibility

**Our Microservices:**

| Service | Language | Purpose | Why This Language? |
|---------|----------|---------|-------------------|
| UI | Java (Spring Boot) | Web interface | Mature ecosystem, enterprise-ready |
| Catalog | Go | Product information API | High performance, low memory footprint |
| Cart | Java (Spring Boot) | Shopping cart management | Good integration with Redis for sessions |
| Orders | Java (Spring Boot) | Order processing | Strong transaction support needed |
| Checkout | Node.js (NestJS) | Checkout orchestration | Async processing, good with APIs |

### 2.2 Why Kubernetes?

Kubernetes (K8s) solves several problems:

1. **Container Orchestration**: Manages hundreds of containers automatically
2. **Self-Healing**: Restarts failed containers, replaces dead nodes
3. **Scaling**: Automatically scales applications based on load
4. **Service Discovery**: Services find each other without hardcoding IPs
5. **Rolling Updates**: Updates applications without downtime
6. **Secret Management**: Stores sensitive data securely

### 2.3 Why GitOps?

GitOps is a way to manage infrastructure using Git as the single source of truth:

```
┌─────────────┐     Push      ┌─────────────┐     Sync     ┌─────────────┐
│   Developer │ ───────────▶ │    Git      │ ◀─────────── │   ArgoCD    │
└─────────────┘              │  Repository │              │(Controller) │
                             └─────────────┘              └──────┬──────┘
                                                                │ Apply
                                                                ▼
                                                          ┌─────────────┐
                                                          │ Kubernetes  │
                                                          │   Cluster   │
                                                          └─────────────┘
```

**Benefits:**
- Version control for infrastructure
- Audit trail of all changes
- Easy rollback (git revert)
- No manual kubectl commands in production
- Declarative configuration

---

## 3. Local Development Setup

### 3.1 Clone the Repository

```bash
# Clone means download a copy of the repository to your local machine
# The repository URL points to where the code is stored on GitHub
git clone https://github.com/Harishmaranthirumaran/retail-store-sample-app.git

# Navigate into the cloned directory
cd retail-store-sample-app

# What's in this directory?
ls -la

# You'll see:
# - src/          : Source code for each microservice
# - gitops/       : Kubernetes manifests for GitOps
# - terraform/    : Infrastructure as Code
# - monitoring/   : Prometheus, Grafana configurations
# - policies/     : Security policies
```

### 3.2 Running with Docker Compose (Simplest Option)

**What is Docker Compose?**
Docker Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application's services, networks, and volumes.

```bash
# The docker-compose.yaml file defines all services and their dependencies
# Let's look at what's inside
cat docker-compose.yaml

# Run all services
# -d flag means "detached mode" - runs in background
# This starts all the containers defined in docker-compose.yaml
docker compose up -d

# What happens when you run this?
# 1. Docker reads docker-compose.yaml
# 2. Downloads (pulls) container images from registry
# 3. Creates a network for the services
# 4. Starts all containers
# 5. Sets up inter-service communication

# Check if containers are running
docker compose ps

# You should see all services with status "Up" or "Running"
# The "Ports" column shows which host port maps to container port

# View logs from all services
# Useful for debugging and understanding what's happening
docker compose logs -f

# Press Ctrl+C to stop following logs

# Access the application
# Open your browser and go to: http://localhost:8888
# You should see the Retail Store UI
```

### 3.3 Running Single Container

```bash
# If you just want to test the UI without the backend services
# This is useful for UI development or quick testing

# Run a single container
# -p maps host port 8888 to container port 8080
# -it makes it interactive (Ctrl+C to stop)
# --rm removes the container when stopped
docker run -it --rm -p 8888:8080 public.ecr.aws/aws-containers/retail-store-sample-ui:1.6.1

# Why port 8888:8080?
# - 8888 is the port on YOUR computer (host)
# - 8080 is the port inside the container
# - This maps them so you can access container via localhost:8888

# The image name format:
# public.ecr.aws           - Registry URL (Amazon ECR Public)
# aws-containers           - Repository owner
# retail-store-sample-ui   - Image name
# :1.6.1                   - Tag (version)
```

### 3.4 Building from Source

```bash
# Install dependencies
# Yarn is a package manager (alternative to npm)
# install downloads all dependencies defined in package.json
yarn install

# Build all services
# nx is a build system for monorepos
# run-many executes a task across multiple projects
# -t build means "target: build"
yarn nx run-many -t build

# Run tests
yarn nx run-many -t test

# This runs unit tests for all services
# Tests verify that each component works correctly
```

---

## 4. AWS Infrastructure Deployment

### 4.1 Understanding Terraform

**Why Terraform?**
Instead of clicking around the AWS console to create resources, we write code. This code can be:
- Version controlled (track changes over time)
- Reviewed (before applying)
- Reused (create identical environments)
- Automated (run in CI/CD)

**Terraform Concepts:**

1. **Provider**: Plugin that lets Terraform interact with APIs (AWS, Azure, etc.)
2. **Resource**: Infrastructure object (EC2, VPC, RDS, etc.)
3. **Module**: Reusable collection of resources
4. **State**: Record of what Terraform has created (stored in terraform.tfstate)
5. **Plan**: Preview of changes Terraform will make
6. **Apply**: Execute the changes

### 4.2 Setting Up Remote State

**Why Remote State?**
When working in a team, you need to share state. Storing state locally means only one person can manage infrastructure. Remote state (in S3) allows collaboration.

```bash
# Create S3 bucket for Terraform state
# S3 (Simple Storage Service) is AWS's object storage
# We use it to store the terraform.tfstate file

# --bucket: Name of the bucket (must be globally unique)
# --region: AWS region where bucket is created
aws s3 mb s3://retail-store-terraform-state-your-name --region us-west-2

# Enable versioning
# This keeps history of all state changes
# If something goes wrong, you can restore previous state
aws s3api put-bucket-versioning \
    --bucket retail-store-terraform-state-your-name \
    --versioning-configuration Status=Enabled

# Enable encryption
# Encrypts state at rest for security
# Terraform state may contain sensitive data!
aws s3api put-bucket-encryption \
    --bucket retail-store-terraform-state-your-name \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Create DynamoDB table for state locking
# This prevents multiple people from applying changes simultaneously
# If two people try to apply at the same time, one waits for the other
aws dynamodb create-table \
    --table-name retail-store-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-west-2
```

### 4.3 Understanding the Terraform Code

Let's look at what the Terraform code creates:

```bash
# Navigate to the Terraform environment
cd terraform/environments/staging

# Look at the main configuration
cat main.tf
```

**Breaking down main.tf:**

```hcl
# terraform block - Configure Terraform itself
terraform {
  required_version = ">= 1.5.0"  # Minimum Terraform version

  # Backend configuration - Where to store state
  backend "s3" {
    bucket         = "retail-store-terraform-state"
    key            = "staging/eks/terraform.tfstate"  # Path within bucket
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "retail-store-terraform-locks"   # For locking
  }

  # Provider requirements
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
  }
}
```

**What does each part mean?**

| Block | Purpose |
|-------|---------|
| `required_version` | Ensures team uses compatible Terraform version |
| `backend "s3"` | Stores state remotely in S3 for collaboration |
| `dynamodb_table` | Prevents concurrent modifications |
| `required_providers` | Specifies which cloud providers we'll use |

### 4.4 Terraform Workflow

```bash
# Step 1: Initialize Terraform
# This downloads providers and initializes the backend
terraform init

# What happens during init?
# - Downloads AWS provider plugin
# - Downloads Kubernetes provider plugin
# - Connects to S3 backend
# - Initializes modules (eks, vpc, security)

# Step 2: Plan what will be created
# This shows you what Terraform will do WITHOUT actually doing it
# Always review the plan before applying!
terraform plan

# The plan shows:
# - Resources to be added (+)
# - Resources to be modified (~)
# - Resources to be destroyed (-)
# - Total count of changes

# You should see something like:
# Plan: 50 to add, 0 to change, 0 to destroy

# Step 3: Apply the changes
# This actually creates the infrastructure
# Type "yes" when prompted to confirm
terraform apply

# This will take 15-30 minutes because:
# - EKS cluster takes time to provision
# - Nodes need to be created
# - Add-ons (CoreDNS, kube-proxy, VPC CNI) need to install

# Step 4: Verify what was created
# Show all outputs (useful values from created resources)
terraform output

# You'll see:
# - cluster_endpoint: API server URL
# - cluster_name: Name of the EKS cluster
# - configure_kubectl: Command to configure kubectl
```

### 4.5 What Terraform Creates

Let's break down each module:

#### VPC Module
```hcl
module "vpc" {
  source = "../modules/vpc"

  vpc_cidr           = "10.0.0.0/16"     # 65,536 IP addresses
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  # Why 3 AZs?
  # - High availability: If one AZ goes down, others handle traffic
  # - Fault tolerance: Spread across multiple physical locations
}
```

**What is a VPC?**
Virtual Private Cloud (VPC) is your own isolated network in AWS. Think of it as a data center in the cloud.

```
                    VPC (10.0.0.0/16)
    ┌────────────────────────────────────────────────┐
    │                                                │
    │   Public Subnet      Public Subnet             │
    │   (10.0.1.0/24)      (10.0.2.0/24)             │
    │   ┌──────────┐       ┌──────────┐              │
    │   │ Load     │       │ NAT      │              │
    │   │ Balancer │       │ Gateway  │              │
    │   └──────────┘       └──────────┘              │
    │                                                │
    │   Private Subnet     Private Subnet            │
    │   (10.0.10.0/24)     (10.0.20.0/24)            │
    │   ┌──────────┐       ┌──────────┐              │
    │   │ EKS      │       │ EKS      │              │
    │   │ Nodes    │       │ Nodes    │              │
    │   └──────────┘       └──────────┘              │
    │                                                │
    └────────────────────────────────────────────────┘
```

#### EKS Module
```hcl
module "eks" {
  source = "../modules/eks"

  cluster_name    = "retail-store-staging"
  cluster_version = "1.28"  # Kubernetes version

  # Node groups define your worker machines
  managed_node_groups = {
    general = {
      instance_types = ["m5.large"]  # 2 vCPU, 8 GB RAM
      min_size       = 2
      max_size       = 10
      desired_size   = 2
    }
  }
}
```

**What is EKS?**
Amazon Elastic Kubernetes Service (EKS) is a managed Kubernetes service. AWS manages the control plane (master nodes), you manage the worker nodes.

---

## 5. Kubernetes Cluster Setup

### 5.1 Configure kubectl

```bash
# Update kubeconfig to connect to the cluster
# This creates a file at ~/.kube/config with cluster credentials
aws eks update-kubeconfig \
    --name retail-store-staging \
    --region us-west-2

# What does this do?
# 1. Gets cluster endpoint URL
# 2. Gets certificate authority data
# 3. Creates context with your AWS credentials
# 4. Writes to ~/.kube/config

# Verify connection
# This sends a request to the Kubernetes API server
kubectl get nodes

# You should see your worker nodes with status "Ready"
# NAME                         STATUS   ROLES    AGE   VERSION
# ip-10-0-10-100.ec2.internal  Ready    <none>   5m    v1.28.0
```

### 5.2 Understanding Kubernetes Objects

**Pod**: Smallest deployable unit, contains one or more containers
**Deployment**: Manages replicas of Pods, handles updates
**Service**: Provides stable network endpoint for Pods
**ConfigMap**: Stores configuration data
**Secret**: Stores sensitive data (passwords, keys)
**Namespace**: Virtual cluster within a cluster

### 5.3 Install Essential Add-ons

```bash
# Install AWS Load Balancer Controller
# This controller manages AWS ALB/NLB for Kubernetes Ingress

# 1. Create IAM service account
# IRSA (IAM Roles for Service Accounts) allows pods to have AWS permissions
eksctl create iamserviceaccount \
    --cluster=retail-store-staging \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy \
    --approve

# What is IRSA?
# Instead of giving ALL pods AWS permissions, we give specific service accounts
# specific permissions. This follows the principle of least privilege.

# 2. Install using Helm
# Helm installs the controller using a pre-made "chart" (package)
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

# Why --set serviceAccount.create=false?
# We already created the service account with IAM permissions above
# We don't want Helm to create a new one without IAM permissions
```

```bash
# Install Metrics Server
# Required for Horizontal Pod Autoscaler (HPA)
# HPA automatically scales pods based on CPU/memory usage

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify installation
kubectl get pods -n kube-system | grep metrics-server

# Test metrics
kubectl top nodes  # Shows node resource usage
kubectl top pods   # Shows pod resource usage
```

```bash
# Install Cluster Autoscaler
# Automatically adds/removes nodes based on pod scheduling needs

# If pods can't be scheduled (not enough resources), autoscaler adds nodes
# If nodes are underutilized, autoscaler removes them

# 1. Create IAM service account
eksctl create iamserviceaccount \
    --cluster=retail-store-staging \
    --namespace=kube-system \
    --name=cluster-autoscaler \
    --attach-policy-arn=arn:aws:iam::aws:policy/AutoScalingFullAccess \
    --approve

# 2. Deploy autoscaler
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
        - name: cluster-autoscaler
          image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.28.0
          command:
            - ./cluster-autoscaler
            - --namespace=kube-system
            - --cloud-provider=aws
            - --skip-nodes-with-local-storage=false
            - --expander=least-waste
          resources:
            limits:
              cpu: 100m
              memory: 300Mi
            requests:
              cpu: 100m
              memory: 300Mi
EOF
```

### 5.4 Understanding the Deployment Manifests

Let's examine a deployment YAML:

```bash
cat gitops/apps/base/ui-deployment.yaml
```

```yaml
apiVersion: apps/v1          # API version for Deployment resource
kind: Deployment             # Type of Kubernetes object
metadata:
  name: ui                   # Name of the deployment
  labels:
    app.kubernetes.io/name: ui    # Label for identification
spec:
  replicas: 2                # Number of pod copies
  selector:
    matchLabels:             # Which pods belong to this deployment
      app.kubernetes.io/name: ui
  template:                  # Template for creating pods
    metadata:
      labels:
        app.kubernetes.io/name: ui
    spec:
      securityContext:       # Security settings for all containers
        runAsNonRoot: true   # Container runs as non-root user
        runAsUser: 1000      # User ID to run as
      containers:
        - name: ui
          image: public.ecr.aws/aws-containers/retail-store-sample-ui:1.6.1
          ports:
            - containerPort: 8080  # Port the container listens on
          resources:
            requests:          # Minimum resources guaranteed
              memory: "512Mi"
              cpu: "200m"      # 200 millicores = 0.2 CPU cores
            limits:            # Maximum resources allowed
              memory: "1Gi"
              cpu: "1000m"     # 1 full CPU core
          readinessProbe:      # Check if pod is ready to receive traffic
            httpGet:
              path: /health/readiness
              port: 8080
            initialDelaySeconds: 30  # Wait before first check
            periodSeconds: 10        # Check every 10 seconds
          livenessProbe:       # Check if pod is still running
            httpGet:
              path: /health/liveness
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 20
```

**Why each part matters:**

| Field | Purpose | Why It Matters |
|-------|---------|---------------|
| `replicas: 2` | Creates 2 pod copies | If one fails, other serves traffic |
| `resources.requests` | Minimum resources | Ensures pod gets needed resources |
| `resources.limits` | Maximum resources | Prevents one pod from using all resources |
| `readinessProbe` | Checks if ready | Only sends traffic to ready pods |
| `livenessProbe` | Checks if alive | Restarts dead/unhealthy pods |
| `securityContext` | Security settings | Reduces attack surface |

---

## 6. GitOps with ArgoCD

### 6.1 What is GitOps?

**Traditional Deployment:**
```bash
kubectl apply -f deployment.yaml  # Manual command in production
```
Problems:
- No audit trail
- Can't see who deployed what
- No easy rollback
- Configuration drift (cluster differs from files)

**GitOps Deployment:**
```
Developer → Git Push → ArgoCD Detects Change → Applies to Cluster
```
Benefits:
- Full audit trail (git history)
- Easy rollback (git revert)
- Single source of truth
- Automated sync

### 6.2 Install ArgoCD

```bash
# Create namespace for ArgoCD
# Namespaces isolate resources, like folders
kubectl create namespace argocd

# Install ArgoCD
# This applies all the manifests needed to run ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# What gets installed?
# - argocd-server: API server and UI
# - argocd-repo-server: Manages git repository access
# - argocd-application-controller: Syncs applications
# - argocd-dex: SSO/OIDC integration
# - redis: Caching
# - Various ConfigMaps and Secrets

# Wait for ArgoCD to be ready
kubectl rollout status deployment/argocd-server -n argocd

# Get initial admin password
# ArgoCD generates a random password during installation
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Note: base64 -d decodes the password (Kubernetes stores secrets in base64)
```

### 6.3 Access ArgoCD UI

```bash
# Expose ArgoCD server
# port-forward creates a tunnel from your machine to the pod
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Now open: https://localhost:8080
# Username: admin
# Password: (from previous command)

# Why port-forward?
# - ArgoCD isn't exposed publicly by default (security)
# - port-forward lets you access it locally
# - For production, you'd use an Ingress with TLS
```

### 6.4 Understand ArgoCD ApplicationSet

```bash
cat gitops/argocd/applicationset.yaml
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet        # Generates multiple Applications
metadata:
  name: retail-store-apps
  namespace: argocd
spec:
  generators:
    - matrix:              # Combine multiple generators
        generators:
          - git:           # Scan Git repository for directories
              repoURL: https://github.com/your-repo/retail-store-sample-app.git
              revision: main
              directories:
                - path: gitops/apps/overlays/*   # Match all overlays
          - list:          # Define environments
              elements:
                - environment: staging
                  server: https://kubernetes.default.svc
                - environment: production
                  server: https://kubernetes.default.svc
  template:
    metadata:
      name: 'retail-store-{{environment}}'  # Template variable
    spec:
      project: default
      source:
        repoURL: https://github.com/your-repo/retail-store-sample-app.git
        targetRevision: main
        path: 'gitops/apps/overlays/{{environment}}'  # Uses Kustomize
      destination:
        server: '{{server}}'
        namespace: 'retail-store-{{environment}}'
      syncPolicy:
        automated:
          prune: true      # Delete resources not in Git
          selfHeal: true   # Fix drift automatically
```

**What this does:**

1. **Generators** create Applications for each environment (staging, production)
2. **Template** defines what each Application looks like
3. **Automated sync** keeps cluster in sync with Git

### 6.5 Deploy the Application

```bash
# Apply the ApplicationSet
# This tells ArgoCD to start managing our application
kubectl apply -f gitops/argocd/applicationset.yaml

# Check ArgoCD applications
argocd app list

# Or using kubectl
kubectl get applications -n argocd

# You should see:
# NAME                    SYNC STATUS   HEALTH STATUS
# retail-store-staging    Synced        Healthy
# retail-store-production OutOfSync     Progressing

# Sync statuses:
# - Synced: Cluster matches Git
# - OutOfSync: Cluster differs from Git
# - Unknown: Can't determine status

# Health statuses:
# - Healthy: All resources working
# - Progressing: Still deploying
# - Degraded: Something is wrong
# - Suspended: Paused

# Force sync if needed
argocd app sync retail-store-staging

# Watch the deployment
argocd app get retail-store-staging --watch
```

### 6.6 Understanding Kustomize

**Why Kustomize?**
We use Kustomize to manage different environments without duplicating YAML files.

```
gitops/apps/
├── base/              # Common configuration for all environments
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── staging/       # Staging-specific changes
    │   ├── kustomization.yaml
    │   └── patches/
    └── production/    # Production-specific changes
        ├── kustomization.yaml
        └── patches/
```

```bash
# View staging kustomization
cat gitops/apps/overlays/staging/kustomization.yaml
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: retail-store-staging  # All resources go to this namespace

resources:
  - ../base                      # Include base resources
  - ingress.yaml                 # Add staging-specific resources
  - hpa.yaml

commonLabels:
  environment: staging           # Add this label to all resources

replicas:
  - name: ui
    count: 2                     # Override replicas from base

images:
  - name: ui
    newTag: "latest"             # Use latest tag for staging
```

**What Kustomize does:**
1. Takes base resources
2. Applies overlays (patches, additions)
3. Generates final YAML

```bash
# Preview what Kustomize will generate
kubectl kustomize gitops/apps/overlays/staging

# Apply directly (without ArgoCD)
kubectl apply -k gitops/apps/overlays/staging
```

---

## 7. Monitoring & Observability

### 7.1 Why Monitoring Matters

You can't manage what you can't measure. Monitoring helps you:

1. **Detect problems** before users notice
2. **Debug issues** when they occur
3. **Plan capacity** for future growth
4. **Optimize costs** by finding waste

### 7.2 Install Prometheus Stack

```bash
# Add Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-charts.storage.googleapis.com
helm repo update

# Install kube-prometheus-stack
# This includes:
# - Prometheus (metrics collection)
# - Alertmanager (alert routing)
# - Grafana (visualization)
# - Node Exporter (node metrics)
# - kube-state-metrics (Kubernetes metrics)
helm install prometheus prometheus-community/kube-prometheus-stack \
    -n monitoring \
    --create-namespace \
    -f gitops/infrastructure/controllers/kube-prometheus-stack.values.yaml

# What do these components do?
#
# Prometheus:
# - Scrapes metrics from applications (pull model)
# - Stores metrics in time-series database
# - Evaluates alerting rules
#
# Grafana:
# - Visualizes metrics in dashboards
# - Supports multiple data sources
# - Alerts based on metrics
#
# Alertmanager:
# - Receives alerts from Prometheus
# - Deduplicates, groups, and routes alerts
# - Sends to Slack, PagerDuty, email, etc.
```

### 7.3 Understanding Prometheus Metrics

Prometheus uses a **pull model**: Prometheus scrapes (fetches) metrics from applications.

```yaml
# Scrape configuration
scrape_configs:
  - job_name: 'retail-store'
    kubernetes_sd_configs:    # Discover pods automatically
      - role: pod
    relabel_configs:          # Filter and label targets
      - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
        action: keep          # Only scrape pods with this label
        regex: ui|catalog|cart|orders|checkout
```

**How applications expose metrics:**
```bash
# Applications expose metrics at /metrics endpoint
curl http://ui:8080/metrics

# Response looks like:
# http_requests_total{method="GET",status="200"} 1234
# http_request_duration_seconds{method="GET",quantile="0.99"} 0.123
```

### 7.4 Accessing Grafana

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open: http://localhost:3000
# Default credentials (check values.yaml):
# Username: admin
# Password: prom-operator

# Import pre-built dashboards
# 1. Go to Dashboards → Import
# 2. Enter dashboard ID or upload JSON file
# 3. Select Prometheus data source
# 4. Click Import

# Useful dashboard IDs:
# - 315: Kubernetes cluster monitoring
# - 1860: Node exporter full
# - 6417: Kubernetes API server
```

### 7.5 Understanding Alerting

```bash
cat monitoring/prometheus/alerting-rules.yaml
```

```yaml
groups:
  - name: retail-store.rules
    rules:
      # Alert when error rate exceeds 1%
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total[5m])) > 0.01
        for: 5m              # Must be true for 5 minutes
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"
```

**How alerts work:**
1. Prometheus evaluates expressions every 15 seconds
2. If expression is true, alert becomes "firing"
3. After `for` duration, alert is sent to Alertmanager
4. Alertmanager routes to appropriate channel (Slack, PagerDuty, etc.)

### 7.6 Setting Up Alert Routing

```bash
cat monitoring/alertmanager/config.yaml
```

```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

route:
  receiver: 'default'
  group_by: ['alertname', 'severity']
  group_wait: 30s        # Wait before sending first notification
  group_interval: 5m     # Wait before sending new group
  repeat_interval: 4h    # Re-send if still firing

  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'

receivers:
  - name: 'default'
    slack_configs:
      - channel: '#alerts'
  
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_KEY'
```

---

## 8. Security Hardening

### 8.1 Why Security Hardening?

Cloud environments are shared responsibility:
- AWS secures the cloud (infrastructure)
- You secure what's in the cloud (applications, data)

Kubernetes is secure by default, but you need to:
1. Limit what pods can do
2. Control network traffic
3. Manage secrets properly
4. Enforce policies

### 8.2 Install OPA Gatekeeper

**What is OPA Gatekeeper?**
Open Policy Agent (OPA) Gatekeeper enforces policies on Kubernetes objects. Think of it as a gatekeeper that checks every resource before it's created.

```bash
# Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

# What gets installed?
# - Gatekeeper controller: Validates resources
# - Gatekeeper audit: Checks existing resources
# - ConstraintTemplates: Define policy templates
# - Constraints: Actual policy instances
```

### 8.3 Understanding Gatekeeper Policies

```bash
cat policies/gatekeeper/container-limits.yaml
```

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: containerlimits
spec:
  crd:
    spec:
      names:
        kind: ContainerLimits
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |                     # Rego is OPA's policy language
        package containerlimits

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.memory
          msg := "Container must have memory limits"
        }

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.cpu
          msg := "Container must have CPU limits"
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: ContainerLimits
metadata:
  name: container-must-have-limits
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
    namespaces:
      - retail-store-production  # Only apply to production
```

**What this does:**
1. When a Deployment is created/updated
2. Gatekeeper intercepts the request
3. Runs the Rego policy
4. If violation, the request is rejected

```bash
# Apply the policy
kubectl apply -f policies/gatekeeper/container-limits.yaml

# Test the policy
# This should fail because no memory limits
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    spec:
      containers:
        - name: nginx
          image: nginx
EOF

# Error: admission webhook denied the request: Container must have memory limits
```

### 8.4 Network Policies

**What are Network Policies?**
By default, all pods can talk to all pods. Network Policies restrict communication.

```bash
cat policies/network-policies/default-deny-all-namespaces.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: retail-store-production
spec:
  podSelector: {}           # Selects all pods in namespace
  policyTypes:
    - Ingress              # Deny all incoming traffic
    - Egress               # Deny all outgoing traffic
```

**This is the "default deny" pattern:**
1. First, deny everything
2. Then, explicitly allow what's needed

```bash
# Apply default deny
kubectl apply -f policies/network-policies/default-deny-all-namespaces.yaml

# Now pods can't talk to each other!
# Let's allow necessary traffic

# Allow DNS (required for service discovery)
kubectl apply -f policies/network-policies/allow-dns.yaml

# Allow traffic from load balancer
kubectl apply -f policies/network-policies/allow-ingress-traffic.yaml

# Allow inter-service communication
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-retail-store-traffic
  namespace: retail-store-production
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/part-of: retail-store
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/part-of: retail-store
EOF
```

### 8.5 External Secrets Operator

**Why External Secrets?**
Storing secrets in Kubernetes Secrets is not ideal:
- Base64 encoded (not encrypted)
- Stored in etcd
- Hard to manage at scale

External Secrets Operator syncs from external secret stores (AWS Secrets Manager, HashiCorp Vault).

```bash
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
    -n external-secrets-system \
    --create-namespace

# Create IAM role for the operator
eksctl create iamserviceaccount \
    --cluster=retail-store-staging \
    --namespace=external-secrets-system \
    --name=external-secrets-sa \
    --attach-policy-arn=arn:aws:iam::aws:policy/SecretsManagerReadWrite \
    --approve

# Configure secret store
kubectl apply -f gitops/infrastructure/controllers/cluster-secret-store.yaml
```

**The Secret Store:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secretsmanager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:    # Uses IAM roles for service accounts
          serviceAccountRef:
            name: external-secrets-sa
            namespace: external-secrets-system
```

**The External Secret:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: 1h       # How often to sync
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: db-secret         # Kubernetes secret to create
    creationPolicy: Owner
  data:
    - secretKey: password   # Key in Kubernetes secret
      remoteRef:
        key: retail-store/database  # AWS Secrets Manager secret name
        property: password   # Property within the secret
```

---

## 9. Service Mesh with Istio

### 9.1 What is a Service Mesh?

A service mesh handles service-to-service communication:
- Traffic management (routing, load balancing)
- Security (mTLS, authorization)
- Observability (tracing, metrics)

```
Without Service Mesh:
┌─────┐      ┌─────┐
│ Pod │─────▶│ Pod │
└─────┘      └─────┘

With Service Mesh (Istio):
┌───────────────┐      ┌───────────────┐
│ ┌─────┐ ┌───┐ │      │ ┌───┐ ┌─────┐ │
│ │ Pod │ │Env│─┼──────┼▶│Env│ │ Pod │ │
│ └─────┘ └───┘ │      │ └───┘ └─────┘ │
│  Sidecar Proxy │      │ Sidecar Proxy │
└───────────────┘      └───────────────┘
```

### 9.2 Install Istio

```bash
# Download Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install Istio
# The operator manages Istio components
istioctl install -f service-mesh/istio/istio-operator.yaml -y

# What gets installed?
# - istiod: Control plane (configures sidecars)
# - istio-ingressgateway: Handles incoming traffic
# - istio-egressgateway: Handles outgoing traffic (optional)

# Enable sidecar injection for namespace
# This adds Envoy proxy to every pod
kubectl label namespace retail-store-production istio-injection=enabled

# Now every pod in this namespace will get an Envoy sidecar
# Verify by checking pod has 2 containers:
kubectl get pods -n retail-store-production
# NAME                   READY   STATUS
# ui-xxx                 2/2     Running   # 2 containers = app + Envoy
```

### 9.3 Understanding Istio Resources

**Gateway:** Entry point for traffic
```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: retail-store-gateway
spec:
  selector:
    istio: ingressgateway  # Use the default ingress gateway
  servers:
    - port:
        number: 443
        name: https
        protocol: HTTPS
      tls:
        mode: SIMPLE
        credentialName: retail-store-tls  # Kubernetes TLS secret
      hosts:
        - "retailstore.example.com"
```

**VirtualService:** Routing rules
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ui
spec:
  hosts:
    - "retailstore.example.com"
  gateways:
    - retail-store-gateway
  http:
    - match:
        - uri:
            prefix: /api/catalog
      route:
        - destination:
            host: catalog
            port:
              number: 8080
      retries:
        attempts: 3
        perTryTimeout: 2s
```

**DestinationRule:** Traffic policies
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: catalog
spec:
  host: catalog
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 3     # Eject after 3 errors
      interval: 30s               # Detection window
      baseEjectionTime: 30s       # How long to eject
      maxEjectionPercent: 30      # Max 30% of pods ejected
    tls:
      mode: ISTIO_MUTUAL          # Enable mTLS
```

### 9.4 Enable mTLS

**What is mTLS?**
Mutual TLS (mTLS) provides:
1. **Authentication**: Services verify each other's identity
2. **Encryption**: Traffic is encrypted
3. **Integrity**: Data can't be tampered with

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: retail-store-production
spec:
  mtls:
    mode: STRICT  # All traffic must use mTLS
```

```bash
# Apply mTLS policy
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: retail-store-production
spec:
  mtls:
    mode: STRICT
EOF

# Verify mTLS is working
istioctl authn tls-check ui-xxx.retail-store-production

# Should show: mTLS
```

---

## 10. Progressive Delivery

### 10.1 What is Progressive Delivery?

Instead of updating all pods at once, we gradually roll out changes:
- Monitor health at each step
- Automatically rollback if problems detected
- Minimize blast radius of bad deployments

**Canary Deployment:**
```
Step 1: 90% v1, 10% v2   → Monitor for 2 minutes
Step 2: 75% v1, 25% v2   → Monitor for 2 minutes
Step 3: 50% v1, 50% v2   → Monitor for 2 minutes
Step 4: 25% v1, 75% v2   → Monitor for 2 minutes
Step 5: 100% v2          → Complete
```

**Blue-Green Deployment:**
```
Blue (v1) is serving production traffic
Green (v2) is deployed but no traffic
Test Green
Switch traffic from Blue to Green
Delete Blue
```

### 10.2 Install Argo Rollouts

```bash
# Install Argo Rollouts controller
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Install kubectl plugin
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-darwin-amd64
chmod +x ./kubectl-argo-rollouts-darwin-amd64
sudo mv ./kubectl-argo-rollouts-darwin-amd64 /usr/local/bin/kubectl-argo-rollouts
```

### 10.3 Understanding Rollout Resource

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: ui-rollout
spec:
  replicas: 3
  revisionHistoryLimit: 10   # Keep 10 old ReplicaSets for rollback
  selector:
    matchLabels:
      app.kubernetes.io/name: ui
  strategy:
    canary:
      maxSurge: "25%"         # Can create 25% extra pods during update
      maxUnavailable: 0       # Never go below desired replicas
      steps:
        - setWeight: 10       # Send 10% traffic to canary
        - pause: {duration: 2m}  # Wait 2 minutes
        - setWeight: 25       # Send 25% traffic to canary
        - pause: {duration: 2m}
        - setWeight: 50
        - pause: {duration: 2m}
        - setWeight: 75
        - pause: {duration: 2m}
      analysis:               # Automatic analysis during rollout
        templates:
          - templateName: success-rate
        startingStep: 1       # Start analysis after step 1
  template:
    spec:
      containers:
        - name: ui
          image: retail-store-sample-ui:v2
```

**Analysis Template:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  metrics:
    - name: success-rate
      interval: 30s          # Check every 30 seconds
      count: 5               # Run 5 times
      successCondition: result[0] > 0.99  # 99% success rate
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            sum(rate(http_requests_total{service="ui",status!~"5.."}[30s]))
            /
            sum(rate(http_requests_total{service="ui"}[30s]))
```

### 10.4 Performing a Rollout

```bash
# Apply the rollout
kubectl apply -f gitops/rollouts/rollouts.yaml

# Check rollout status
kubectl argo rollouts get rollout ui-rollout

# Watch the rollout
kubectl argo rollouts get rollout ui-rollout --watch

# You'll see:
# Name:            ui-rollout
# Status:          Progressing
# Replicas:
#   Desired:       3
#   Current:       4  (extra pod for canary)
#   Up-to-date:    1
#   Available:     3

# Promote to next step manually (if needed)
kubectl argo rollouts promote ui-rollout

# Abort a rollout
kubectl argo rollouts abort ui-rollout

# Retry a failed rollout
kubectl argo rollouts retry ui-rollout
```

---

## 11. Chaos Engineering

### 11.1 What is Chaos Engineering?

Chaos Engineering is disciplined approach to identifying failures before they become outages. We intentionally inject failures to:
- Find weaknesses
- Build confidence
- Practice recovery

### 11.2 Install Chaos Mesh

```bash
# Add Chaos Mesh Helm repository
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

# Create namespace
kubectl create namespace chaos-testing

# Install Chaos Mesh
helm install chaos-mesh chaos-mesh/chaos-mesh \
    --namespace=chaos-testing \
    --set chaosDaemon.runtime=containerd \
    --set chaosDaemon.socketPath=/run/containerd/containerd.sock \
    --set dashboard.create=true

# Port-forward dashboard
kubectl port-forward -n chaos-testing svc/chaos-dashboard 2333:2333

# Open: http://localhost:2333
```

### 11.3 Types of Chaos Experiments

**Pod Kill:** Simulate pod failures
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: catalog-pod-kill
spec:
  action: pod-kill          # Action to perform
  mode: one                 # Kill one pod
  selector:
    namespaces:
      - retail-store-production
    labelSelectors:
      app.kubernetes.io/name: catalog
  scheduler:
    cron: "0 4 * * *"       # Run daily at 4 AM
```

**Network Latency:** Simulate slow network
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: catalog-latency
spec:
  action: delay
  mode: all
  selector:
    namespaces:
      - retail-store-production
    labelSelectors:
      app.kubernetes.io/name: catalog
  delay:
    latency: "100ms"        # Add 100ms latency
    jitter: "10ms"          # Random variation
  duration: "120s"          # Run for 2 minutes
```

**CPU Stress:** Simulate high CPU load
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: checkout-cpu-stress
spec:
  mode: one
  selector:
    namespaces:
      - retail-store-production
    labelSelectors:
      app.kubernetes.io/name: checkout
  stressors:
    cpu:
      workers: 2            # Number of CPU stress workers
      load: 80              # Load percentage
  duration: "90s"
```

### 11.4 Running Chaos Experiments

```bash
# Apply chaos experiment
kubectl apply -f chaos-engineering/experiments/chaos-mesh.yaml

# Monitor the experiment
kubectl describe podchaos catalog-pod-kill -n chaos-testing

# Check if application survives
kubectl get pods -n retail-store-production
kubectl logs -l app.kubernetes.io/name=catalog -n retail-store-production

# Clean up experiment
kubectl delete -f chaos-engineering/experiments/chaos-mesh.yaml
```

---

## 12. Disaster Recovery

### 12.1 Why Disaster Recovery?

Things will fail:
- AWS region outage
- Database corruption
- Ransomware attack
- Human error

You need to:
1. Backup regularly
2. Test restoration
3. Have runbooks

### 12.2 Install Velero

**What is Velero?**
Velero backs up Kubernetes resources and persistent volumes.

```bash
# Download Velero
wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-darwin-amd64.tar.gz
tar -xzf velero-v1.12.0-darwin-amd64.tar.gz
sudo mv velero-v1.12.0-darwin-amd64/velero /usr/local/bin/

# Create S3 bucket for backups
aws s3 mb s3://retail-store-velero-backups --region us-west-2

# Install Velero with AWS plugin
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.0 \
    --bucket retail-store-velero-backups \
    --backup-location-config region=us-west-2 \
    --snapshot-location-config region=us-west-2 \
    --use-node-agent \
    --wait

# What gets installed?
# - Velero server (controller)
# - Node agent (for volume backups)
# - Backup storage location (S3)
# - Volume snapshot location (EBS snapshots)
```

### 12.3 Creating Backups

```bash
# Create a manual backup
velero backup create manual-backup-$(date +%Y%m%d) \
    --include-namespaces retail-store-production \
    --default-volumes-to-fs-backup

# What does this do?
# 1. Snapshots all EBS volumes
# 2. Exports all Kubernetes resources (Deployments, Services, ConfigMaps, etc.)
# 3. Uploads everything to S3

# Check backup status
velero backup describe manual-backup-$(date +%Y%m%d) --details

# Schedule daily backups
velero schedule create daily-backup \
    --schedule="0 3 * * *" \
    --include-namespaces retail-store-production \
    --default-volumes-to-fs-backup \
    --ttl 2160h  # Keep for 90 days

# List all backups
velero backup get
```

### 12.4 Restoring From Backup

```bash
# Simulate a disaster (don't do this in production!)
kubectl delete namespace retail-store-production

# Verify namespace is gone
kubectl get ns

# Restore from backup
velero restore create restore-$(date +%Y%m%d) \
    --from-backup daily-backup-$(date +%Y%m%d)

# Check restore status
velero restore describe restore-$(date +%Y%m%d)

# Verify restoration
kubectl get all -n retail-store-production
```

### 12.5 DR Runbook

Every team needs a runbook for disasters. See `disaster-recovery/runbooks/dr-runbook.md` for:
- RTO/RPO targets
- Contact information
- Step-by-step recovery procedures
- Escalation matrix

---

## 13. Troubleshooting

### 13.1 Common Issues and Solutions

#### Pods not starting
```bash
# Check pod status
kubectl get pods -n retail-store-production

# Describe pod for events
kubectl describe pod ui-xxx -n retail-store-production

# Check logs
kubectl logs ui-xxx -n retail-store-production

# Common issues:
# - ImagePullBackOff: Image doesn't exist or no permissions
# - CrashLoopBackOff: Application crashing
# - Pending: No resources available (CPU/memory)
```

#### Service not accessible
```bash
# Check service
kubectl get svc -n retail-store-production

# Check endpoints
kubectl get endpoints ui -n retail-store-production

# If endpoints is empty, pods aren't ready
# Check pod readiness probes
kubectl describe pod ui-xxx -n retail-store-production | grep -A 10 Readiness
```

#### ArgoCD not syncing
```bash
# Check application status
argocd app get retail-store-production

# Check for sync errors
argocd app history retail-store-production

# Manual sync
argocd app sync retail-store-production --force
```

#### Horizontal Pod Autoscaler not working
```bash
# Check HPA status
kubectl get hpa -n retail-store-production

# Check metrics server
kubectl top nodes
kubectl top pods -n retail-store-production

# If metrics unavailable, check metrics-server
kubectl logs -n kube-system deployment/metrics-server
```

### 13.2 Useful Commands Reference

```bash
# Get all resources in namespace
kubectl get all -n retail-store-production

# Watch resources
kubectl get pods -n retail-store-production -w

# Execute command in pod
kubectl exec -it ui-xxx -n retail-store-production -- /bin/sh

# Copy file from pod
kubectl cp retail-store-production/ui-xxx:/app/logs ./logs

# Port-forward for debugging
kubectl port-forward svc/ui 8080:8080 -n retail-store-production

# View resource quota
kubectl describe quota -n retail-store-production

# View resource usage
kubectl top pods -n retail-store-production
kubectl top nodes

# Force delete pod (stuck in Terminating)
kubectl delete pod ui-xxx -n retail-store-production --force --grace-period=0

# View all events
kubectl get events -n retail-store-production --sort-by='.lastTimestamp'
```

---

## Conclusion

You now have a production-ready infrastructure with:

1. **GitOps** - ArgoCD managing all deployments
2. **Infrastructure as Code** - Terraform modules for all AWS resources
3. **CI/CD** - GitHub Actions pipelines
4. **Observability** - Prometheus, Grafana, AlertManager
5. **Security** - OPA Gatekeeper, Network Policies, External Secrets
6. **Service Mesh** - Istio with mTLS
7. **Progressive Delivery** - Argo Rollouts
8. **Chaos Engineering** - Chaos Mesh
9. **Disaster Recovery** - Velero backups

### Next Steps

1. Customize configurations for your environment
2. Set up your AWS credentials and domain
3. Run through each section step by step
4. Practice disaster recovery
5. Run chaos experiments regularly

### Further Learning

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

---

*This guide was created to help developers understand not just WHAT to do, but WHY each step is necessary. Every command and configuration has been explained with the reasoning behind it.*
