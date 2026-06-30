# Disaster Recovery Runbook

## Overview
This runbook provides step-by-step procedures for disaster recovery scenarios for the Retail Store application.

## RTO and RPO Targets

| Environment | RTO | RPO | Backup Frequency |
|-------------|-----|-----|------------------|
| Staging | 2 hours | 24 hours | Daily 05:00 UTC |
| Production | 1 hour | 1 hour | Every 4 hours |

## Contact Information

| Role | Name | Email | Phone |
|------|------|-------|-------|
| Incident Commander | Platform Lead | platform@example.com | +1-xxx-xxx-xxxx |
| Database Admin | DBA Team | dba@example.com | +1-xxx-xxx-xxxx |
| Security Officer | Security Team | security@example.com | +1-xxx-xxx-xxxx |

## Scenarios

### Scenario 1: Region Failure (AWS)

**Severity: Critical**

#### Immediate Actions (First 15 minutes)
1. Assess scope of failure
   - Check AWS Health Dashboard
   - Verify CloudWatch alarms
   - Confirm region status

2. Activate backup region
   ```bash
   # Switch DNS to backup region
   aws route53 change-resource-record-sets \
     --hosted-zone-id $ZONE_ID \
     --change-batch file://failover-dns.json
   ```

3. Suspend scheduled jobs
   ```bash
   kubectl suspend cronjob -n retail-store-production load-generator
   ```

#### Recovery Actions (15-60 minutes)
1. Restore from Velero backup in backup region
   ```bash
   velero restore create --from-backup daily-backup-production-latest
   velero restore get
   velero restore describe restore-latest
   ```

2. Verify database replication
   ```bash
   # Check RDS standby status
   aws rds describe-db-instances \
     --db-instance-identifier retail-store-prod \
     --query 'DBInstances[0].DBInstanceStatus'
   ```

3. Restore application data
   ```bash
   # Apply Kubernetes manifests
   kubectl apply -k gitops/apps/overlays/production
   
   # Wait for rollout
   kubectl rollout status deployment -n retail-store-production
   ```

#### Post-Recovery
1. Run smoke tests
2. Verify SLOs are met
3. Update status page
4. Notify stakeholders

### Scenario 2: Database Failure

**Severity: Critical**

#### Immediate Actions
1. Check RDS status
   ```bash
   aws rds describe-db-instances \
     --db-instance-identifier retail-store-prod-db
   ```

2. Initiate failover
   ```bash
   aws rds reboot-db-instance \
     --db-instance-identifier retail-store-prod-db \
     --force-failover
   ```

3. Verify connectivity
   ```bash
   kubectl exec -it -n retail-store-production deploy/orders -- \
     pg_isready -h $RDS_ENDPOINT
   ```

### Scenario 3: Kubernetes Control Plane Failure

**Severity: High**

#### Immediate Actions
1. Check EKS cluster status
   ```bash
   aws eks describe-cluster --name retail-store-production
   kubectl get nodes
   ```

2. Create support ticket with AWS
3. Prepare for cluster recreation

#### Recovery Actions
1. Create new cluster
   ```bash
   cd terraform/environments/production
   terraform apply -var="cluster_name=retail-store-prod-dr"
   ```

2. Restore workloads
   ```bash
   velero restore create --from-backup daily-backup-production-latest
   ```

### Scenario 4: Ransomware / Data Corruption

**Severity: Critical**

#### Immediate Actions
1. **DO NOT** attempt to recover immediately
2. Isolate affected systems
   ```bash
   kubectl scale deployment --all -n retail-store-production --replicas=0
   ```

3. Preserve evidence
   - Take volume snapshots
   - Capture audit logs
   - Document timeline

4. Contact Security Team

#### Recovery Actions
1. Identify clean backup point
2. Restore from verified backup
3. Rotate all credentials
4. Conduct forensic analysis

## Backup Verification

### Daily Verification Checklist
- [ ] Velero backup completed successfully
- [ ] Backup integrity verified
- [ ] Volume snapshots created
- [ ] Database backup validated
- [ ] Secrets backed up separately

### Weekly DR Drill
```bash
# Run DR drill in isolated namespace
velero restore create dr-drill-$(date +%Y%m%d) \
  --from-backup daily-backup-production-latest \
  --namespace-mappings retail-store-production:retail-store-dr-test
```

## Escalation Matrix

1. **Level 1**: Application issues (SLA breach warnings)
2. **Level 2**: Infrastructure issues (partial availability loss)
3. **Level 3**: Regional failure (complete availability loss)

## Communication Templates

### Internal Notification
> **CRITICAL: Retail Store Production Down**
> 
> Time: [TIMESTAMP]
> Impact: [DESCRIPTION]
> RTO: [X] hours
> Status: INVESTIGATING
> Incident Commander: [NAME]
> Join bridge: [BRIDGE_URL]

### Customer Notification
> **Service Disruption Notice**
> 
> We are currently experiencing a service disruption affecting [SERVICES].
> Our team is actively working on restoring service.
> 
> Status page: https://status.retailstore.example.com

## Post-Incident Actions
1. Conduct postmortem within 48 hours
2. Update runbooks based on lessons learned
3. Implement remediation actions
4. Schedule additional DR drills
