# Making This Project Work with $200 AWS Credits

## Reality Check: What $200 Gets You

| Resource | Cost | Duration | Notes |
|----------|------|----------|-------|
| EKS Cluster | $0.10/hr | ~30 days | Control plane only |
| 2x t3.medium nodes | $0.04/hr each | ~25 days | 2 vCPU, 4GB each |
| 1x RDS t3.micro | $0.02/hr | ~30 days | Free tier eligible |
| NAT Gateway | $0.045/hr | Avoid! | Use public subnets instead |
| Load Balancer | $0.022/hr | ~30 days | Required for access |

**Key Strategy**: Skip NAT Gateway ($32/month savings), use smallest instances, destroy when not testing.

## Option 1: Minimal Demo (Recommended)

Run a **working demo** for interviews, then destroy it.

```bash
# Create minimal cluster (no NAT Gateway = big savings)
eksctl create cluster \
    --name retail-demo \
    --region us-west-2 \
    --node-type t3.medium \
    --nodes 2 \
    --node-volume-size 20 \
    --managed \
    --vpc-public-access-only

# Takes ~15 minutes
# Cost: ~$50-75 for full demo day
```

## Option 2: Local Kubernetes (FREE - Best for Learning)

Run everything locally with **kind** or **minikube**:

```bash
# Install kind (Kubernetes in Docker)
brew install kind

# Create local cluster
kind create cluster --name retail-demo

# This is FREE and lets you test:
# - ArgoCD
# - All application deployments
# - Prometheus/Grafana
# - Security policies
# Only difference: No AWS-specific services (use mocks)
```

## Option 3: Spot the Interview Demo Script

Create a repeatable 2-hour demo you can run during interviews:

```bash
# 1. Create cluster (5 min setup, 15 min provision)
# 2. Deploy ArgoCD (2 min)
# 3. Deploy application (5 min)
# 4. Show dashboards (10 min)
# 5. Destroy everything (5 min)
# Total cost: ~$3-5 per demo
```

## Your Interview Demo Script

### Part 1: Infrastructure (Show on screen share)
```bash
# Show your Terraform code
cat terraform/environments/staging/main.tf

# Explain: "Here's my EKS module with IRSA, KMS encryption"
# Point out: Security best practices you implemented
```

### Part 2: GitOps (Most impressive part)
```bash
# Show ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Walk through:
# - ApplicationSets
# - Kustomize overlays
# - Sync policies
```

### Part 3: Observability
```bash
# Show Grafana dashboards you created
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Explain alerting rules and SLOs
```

### Part 4: Security
```bash
# Show Gatekeeper policies
kubectl get constraints

# Show Network Policies
kubectl get networkpolicies -A
```

## What to Actually Deploy with $200

### Deploy Once, Document, Destroy

| Phase | What to Do | Cost |
|-------|------------|------|
| **Phase 1** | Create EKS cluster, deploy app, screenshot everything | ~$20 |
| **Phase 2** | Install ArgoCD, sync apps, capture demo | ~$10 |
| **Phase 3** | Install Prometheus, import dashboards | ~$5 |
| **Phase 4** | Record a 10-minute video walkthrough | ~$5 |
| **Total** | ~$40 | Keep $160 for future interviews |

### Screenshots to Capture (Interview Gold)

1. **ArgoCD dashboard** showing all apps synced
2. **Grafana dashboard** with your custom metrics
3. **Kubernetes resources** `kubectl get all`
4. **Security policies** applied
5. **Terraform plan output** showing infrastructure

## Set Up Budget Alerts (Critical!)

```bash
# Set billing alert at $50
aws budgets create-budget \
    --account-id YOUR_ACCOUNT_ID \
    --budget file://budget.json

# Create budget.json:
{
    "BudgetLimit": {
        "Amount": 50,
        "Unit": "USD"
    },
    "BudgetName": "retail-store-budget",
    "BudgetType": "COST",
    "TimeUnit": "MONTHLY"
}
```

## Quick Destroy Script

```bash
# Run this when done testing!
#!/bin/bash
# destroy-everything.sh

# Delete cluster (biggest cost)
eksctl delete cluster --name retail-demo --region us-west-2

# Or if using terraform
cd terraform/environments/staging
terraform destroy -auto-approve

# Verify nothing running
aws eks list-clusters --region us-west-2
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId'
aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier'
```

## Alternative: Use AWS Free Tier Smart

Services with **12 months free tier**:
- EC2 t2.micro/t3.micro (750 hrs/month)
- RDS t2.micro/t3.micro (750 hrs/month)
- S3 (5GB)
- CloudWatch (10 metrics, 10 alarms)

**Free tier architecture:**
```bash
# Instead of EKS, use single EC2 + Docker Compose
# Cost: $0 (free tier)

# EC2 instance
aws ec2 run-instances \
    --image-id ami-xxx \
    --instance-type t3.micro \
    --key-name your-key

# SSH in and run
docker compose up -d

# Still demonstrates:
# - Container deployment
# - Application architecture
# - Your understanding of Docker
# Cost: $0 if within free tier limits
```

## Summary: What $200 Buys You

| Approach | What You Get | Portfolios Value |
|----------|-------------|-----------------|
| **Local (kind)** | Full K8s stack, $0 cost | High - shows skills |
| **Minimal EKS** | Real AWS experience | High - real demos |
| **Screenshots** | Proof it worked | Medium - static |
| **Video demo** | Walkthrough | High - interview ready |

## My Recommendation

1. **Use kind/minikube locally** - develop and test for free
2. **Spend $50-100** on one real AWS deployment
3. **Screenshot and record video** of it working
4. **Destroy immediately** after
5. **Keep remaining credits** for interview demos where you can spin up live

Your portfolio value comes from:
- The **code** (which you have)
- The **documentation** (which you have)
- **Demonstrating** knowledge in interviews

You don't need it running 24/7.
