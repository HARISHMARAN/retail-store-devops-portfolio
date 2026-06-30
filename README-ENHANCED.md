# Retail Store Sample Application - Production-Ready DevOps Portfolio

![Architecture](docs/images/architecture.png)

## Overview

This is an enhanced version of the AWS Containers Retail Sample Application, transformed into a **production-ready, enterprise-grade deployment** suitable for demonstrating advanced DevOps skills (3+ years experience level).

## What's New in This Enhancement

This project has been significantly enhanced from a basic sample application to demonstrate:

- **Full GitOps Workflow** with ArgoCD ApplicationSets
- **Multi-environment Deployments** (Staging/Production) with Kustomize
- **Infrastructure as Code** (Terraform modules for EKS, VPC, Security)
- **CI/CD Pipelines** (GitHub Actions with security scanning)
- **Observability Stack** (Prometheus, Grafana, AlertManager, Loki)
- **Service Mesh** (Istio with mTLS and traffic management)
- **Progressive Delivery** (Argo Rollouts with canary/blue-green)
- **Chaos Engineering** (Chaos Mesh experiments)
- **Disaster Recovery** (Velero backups, DR runbooks)
- **Security Hardening** (OPA Gatekeeper, Network Policies, External Secrets)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AWS Cloud Infrastructure                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                   │
│  │   Route 53   │───▶│   ALB/NLB    │───▶│   Istio GW   │                   │
│  └──────────────┘    └──────────────┘    └──────────────┘                   │
│                                                   │                         │
│                          ┌────────────────────────┴─────────────────────┐  │
│                          │            EKS Cluster                       │  │
│                          ├─────────────────────────────────────────────┤  │
│                          │                                             │  │
│  ┌────────────────────┐  │  ┌────────┐  ┌────────┐  ┌────────┐         │  │
│  │  ArgoCD            │  │  │   UI   │  │Catalog │  │  Cart  │         │  │
│  │  (GitOps)          │  │  │ (Java) │  │  (Go)  │  │ (Java) │         │  │
│  └────────────────────┘  │  └────────┘  └────────┘  └────────┘         │  │
│                          │       │           │           │              │  │
│  ┌────────────────────┐  │       │           │           │              │  │
│  │  Prometheus/       │  │  ┌────────┐  ┌────────┐  ┌────────┐         │  │
│  │  Grafana Stack      │  │  │ Orders │  │Checkout│  │Recommend│        │  │
│  └────────────────────┘  │  │ (Java) │  │ (Node) │  │ (Python)│         │  │
│                          │  └────────┘  └────────┘  └────────┘         │  │
│  ┌────────────────────┐  │                                             │  │
│  │  Chaos Mesh        │  │  ┌─────────────────────────────────────┐   │  │
│  └────────────────────┘  │  │          Service Mesh (Istio)        │   │  │
│                          │  │  ┌─────────┐  ┌──────────────────┐   │   │  │
│  ┌────────────────────┐  │  │  │  mTLS   │  │ Traffic Policies  │   │   │  │
│  │  OPA Gatekeeper    │  │  │  └─────────┘  └──────────────────┘   │   │  │
│  └────────────────────┘  │  └─────────────────────────────────────┘   │  │
│                          └─────────────────────────────────────────────┘  │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Data Layer                                    │   │
│  ├────────────────┬────────────────┬────────────────┬──────────────────┤   │
│  │  Aurora RDS    │  ElastiCache   │  DynamoDB      │  S3 (Assets)     │   │
│  │  (PostgreSQL)  │  (Redis)        │  (Session)     │                  │   │
│  └────────────────┴────────────────┴────────────────┴──────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Authentication & Secrets                        │   │
│  ├────────────────────────────────────────────────────────────────────┤   │
│  │  Secrets Manager  │  External Secrets  │  IRSA Roles  │  KMS Keys  │   │
│  └────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
retail-store-sample-app/
├── .github/
│   ├── workflows/
│   │   ├── ci.yaml              # Build, test, security scan
│   │   ├── cd.yaml              # Deploy to staging/production
│   │   └── terraform.yaml       # Infrastructure deployment
│   └── actions/                 # Reusable composite actions
│
├── gitops/
│   ├── argocd/
│   │   ├── applicationset.yaml  # Multi-cluster deployments
│   │   └── project.yaml         # ArgoCD project config
│   ├── apps/
│   │   ├── base/                # Kustomize base manifests
│   │   └── overlays/
│   │       ├── staging/
│   │       └── production/
│   ├── infrastructure/
│   │   ├── controllers/         # Helm releases
│   │   └── configs/             # Cluster-wide configs
│   └── rollouts/
│       ├── rollouts.yaml        # Argo Rollouts definitions
│       └── analysis-templates.yaml
│
├── terraform/
│   ├── modules/
│   │   ├── eks/                 # EKS cluster module
│   │   ├── vpc/                 # Network module
│   │   ├── security/            # Security groups, IAM
│   │   └── monitoring/          # Amazon Managed Prometheus
│   └── environments/
│       ├── staging/
│       └── production/
│
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yaml
│   │   ├── scrape-configs.yaml
│   │   ├── recording-rules.yaml
│   │   └── alerting-rules.yaml
│   ├── grafana/dashboards/
│   └── alertmanager/
│
├── policies/
│   ├── gatekeeper/              # OPA policies
│   ├── network-policies/
│   ├── pod-security/
│   └── rbac/
│
├── service-mesh/
│   ├── istio/
│   ├── traffic-management/
│   └── security/
│
├── chaos-engineering/
│   ├── experiments/
│   ├── schedules/
│   └── workflows/
│
├── disaster-recovery/
│   ├── backup/
│   ├── restore/
│   ├── velero/
│   └── runbooks/
│
└── src/                         # Application source code
    ├── ui/
    ├── catalog/
    ├── cart/
    ├── orders/
    ├── checkout/
    └── load-generator/
```

## Key Features

### 1. GitOps with ArgoCD
- **ApplicationSets** for multi-environment deployments
- **Kustomize overlays** for environment-specific configurations
- **Automatic sync** with health checks
- **Rollback** capabilities

### 2. Infrastructure as Code
- Production-ready **Terraform modules** for EKS
- **IRSA (IAM Roles for Service Accounts)** for least-privilege
- **Karpenter** and **Cluster Autoscaler** support
- **VPC endpoints** for secure communication

### 3. CI/CD Pipeline
- **GitHub Actions** with proper stages
- **Security scanning**: Trivy, Snyk, tfsec
- **Multi-architecture builds**: x86-64 and ARM64
- **Image signing** with Cosign
- **SBOM generation**

### 4. Observability
- **Prometheus** with custom recording and alerting rules
- **Grafana** dashboards for application, cluster, and business metrics
- **AlertManager** with Slack, PagerDuty, and email integrations
- **Loki** for log aggregation

### 5. Security Hardening
- **OPA Gatekeeper** policies for pod security
- **Network Policies** for segmentation
- **External Secrets Operator** for secrets management
- **Pod Security Standards** (Restricted profile)
- **mTLS** with Istio

### 6. Progressive Delivery
- **Argo Rollouts** for canary and blue-green deployments
- **Analysis templates** for automated rollback
- **Prometheus-based** analysis queries

### 7. Service Mesh
- **Istio** with mTlS enabled
- **Traffic management** (VirtualServices, DestinationRules)
- **Authorization policies** for zero-trust
- **Circuit breaker** patterns

### 8. Chaos Engineering
- **Chaos Mesh** experiments
- **Scheduled chaos** for game days
- **Pod kill**, **network latency**, **CPU stress** experiments

### 9. Disaster Recovery
- **Velero** for backups and restores
- **Cross-region replication**
- **RTO/RPO** targets defined
- **Runbooks** for various scenarios

## Quick Start

### Prerequisites
- AWS CLI configured
- kubectl installed
- Terraform >= 1.5.0
- Docker

### Local Development
```bash
# Run with Docker Compose
docker compose up

# Or run single container
docker run -p 8888:8080 public.ecr.aws/aws-containers/retail-store-sample-ui:1.6.1
```

### Deploy to AWS

#### 1. Create Infrastructure
```bash
cd terraform/environments/staging
terraform init
terraform plan
terraform apply
```

#### 2. Configure kubectl
```bash
aws eks update-kubeconfig --name retail-store-staging --region us-west-2
```

#### 3. Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### 4. Deploy Application
```bash
kubectl apply -f gitops/argocd/applicationset.yaml
```

### Monitoring Access
```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

## SLOs and SLAs

| Metric | Staging | Production |
|--------|---------|------------|
| Availability | 99% | 99.9% |
| Latency (p99) | < 1s | < 500ms |
| Error Rate | < 2% | < 0.1% |
| RTO | 2 hours | 1 hour |
| RPO | 24 hours | 1 hour |

## Cost Estimation (Monthly)

| Component | Staging | Production |
|-----------|---------|-------------|
| EKS Cluster | $146 | $438 |
| EC2 Nodes | $200 | $600 |
| RDS Aurora | $150 | $450 |
| ElastiCache | $80 | $240 |
| Load Balancers | $50 | $150 |
| **Total** | ~$626 | ~$1,878 |

*Note: Costs vary based on usage and AWS region*

## Security Considerations

1. **Never commit secrets** - Use External Secrets Operator
2. **Enable audit logging** - CloudTrail + EKS control plane logs
3. **Regular patching** - Automated by EKS managed node groups
4. **Network segmentation** - Network policies enforced
5. **mTLS everywhere** - Istio service mesh

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the infrastructure patterns
4. Submit a pull request

## License

This project is licensed under the MIT-0 License - see the [LICENSE](LICENSE) file for details.

## Credits

Based on the [AWS Containers Retail Sample App](https://github.com/aws-containers/retail-store-sample-app) with significant enhancements for production-readiness.

## Portfolio Value

This project demonstrates:

✅ **Senior-level Terraform** skills (modules, state management, IaC patterns)

✅ **Kubernetes expertise** (Kustomize, Helm, GitOps, RBAC)

✅ **CI/CD pipeline** design (multi-stage, security scanning, deployment strategies)

✅ **Observability** implementation (metrics, logs, traces, alerting)

✅ **Security hardening** (OPA policies, network segmentation, secrets management)

✅ **Service mesh** experience (Istio traffic management, mTLS)

✅ **Disaster recovery** planning (backup strategies, runbooks, RTO/RPO)

✅ **Progressive delivery** (canary deployments, automated rollback)

✅ **Chaos engineering** implementation

This portfolio project showcases the breadth and depth expected for **Senior DevOps Engineer** or **Platform Engineer** roles (3+ years experience).

---

*Last updated: 2025*
