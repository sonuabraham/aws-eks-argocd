# LoadBalancer Configuration Guide

This guide explains how LoadBalancers are configured in this project and common issues you might encounter.

## Default Configuration

The guestbook application is configured with an **internet-facing** LoadBalancer for external access.

### Service Configuration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: guestbook-ui
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-type: external
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: guestbook-ui
```

## Key Annotations

### Internet-Facing LoadBalancer

```yaml
annotations:
  service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```

- **internet-facing**: LoadBalancer is accessible from the internet
- **internal**: LoadBalancer is only accessible within the VPC (default if not specified)

### LoadBalancer Type

```yaml
annotations:
  service.beta.kubernetes.io/aws-load-balancer-type: external
```

- **external**: Creates a Classic Load Balancer or Network Load Balancer
- **nlb**: Explicitly creates a Network Load Balancer
- **alb**: Creates an Application Load Balancer (requires AWS Load Balancer Controller)

## Common Issues

### Issue 1: LoadBalancer is Internal

**Symptom:** Cannot access LoadBalancer URL from your laptop

**Cause:** Missing `internet-facing` annotation

**Solution:**

```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```

### Issue 2: Connection Timeout

**Symptom:** LoadBalancer URL times out

**Possible Causes:**

1. LoadBalancer is internal (not internet-facing)
2. Security group doesn't allow inbound traffic
3. LoadBalancer is still provisioning

**Solutions:**

**Check LoadBalancer scheme:**

```bash
aws elbv2 describe-load-balancers --region us-east-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `guestbook`)].{Name:LoadBalancerName,Scheme:Scheme,State:State.Code}'
```

**Check security groups:**

```bash
# Get LoadBalancer security groups
aws elbv2 describe-load-balancers --region us-east-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `guestbook`)].SecurityGroups[]' \
  --output text

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx --region us-east-1
```

**Wait for provisioning:**

```bash
# Check LoadBalancer state
kubectl get svc guestbook-ui -n default -w
```

### Issue 3: LoadBalancer Not Created

**Symptom:** Service stays in pending state

**Possible Causes:**

1. No available subnets
2. IAM permissions missing
3. Service quota exceeded

**Check service events:**

```bash
kubectl describe svc guestbook-ui -n default
```

## Updating LoadBalancer Configuration

### Method 1: Update via GitOps (Recommended)

1. Update service.yaml in Gitea repository
2. Commit and push changes
3. ArgoCD will sync automatically
4. Delete the service to force recreation:
   ```bash
   kubectl delete svc guestbook-ui -n default
   ```

### Method 2: Direct kubectl Update

```bash
# Edit service
kubectl edit svc guestbook-ui -n default

# Add annotations
kubectl annotate svc guestbook-ui -n default \
  service.beta.kubernetes.io/aws-load-balancer-scheme=internet-facing

# Delete and recreate
kubectl delete svc guestbook-ui -n default
# ArgoCD will recreate it
```

## LoadBalancer Types Comparison

| Type               | Use Case                 | Cost   | Features                            |
| ------------------ | ------------------------ | ------ | ----------------------------------- |
| **Classic LB**     | Simple HTTP/TCP          | Low    | Basic load balancing                |
| **Network LB**     | High performance TCP/UDP | Medium | Ultra-low latency, static IP        |
| **Application LB** | HTTP/HTTPS with routing  | Medium | Path-based routing, WAF integration |

## Best Practices

### For Development/Testing

- Use **internet-facing** for external access
- Use **ClusterIP** + port-forward for local testing (no cost)
- Use **NodePort** for simple external access without LoadBalancer

### For Production

- Use **Application Load Balancer** with AWS Load Balancer Controller
- Enable **SSL/TLS** termination
- Configure **health checks**
- Set up **access logs**
- Use **security groups** to restrict access

## Alternative Access Methods

### Port-Forward (No LoadBalancer Cost)

```bash
kubectl port-forward svc/guestbook-ui -n default 8081:80
# Access at: http://localhost:8081
```

**Pros:**

- No AWS costs
- Works immediately
- Good for development

**Cons:**

- Only accessible from your laptop
- Requires kubectl access
- Connection can drop

### NodePort

```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

**Access via:**

```bash
# Get node external IP
kubectl get nodes -o wide

# Access at: http://NODE_IP:30080
```

### Ingress (Requires Ingress Controller)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guestbook
spec:
  rules:
    - host: guestbook.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: guestbook-ui
                port:
                  number: 80
```

## Troubleshooting Commands

```bash
# Check service status
kubectl get svc guestbook-ui -n default

# Check service details
kubectl describe svc guestbook-ui -n default

# Check LoadBalancer in AWS
aws elbv2 describe-load-balancers --region us-east-1

# Check target health
aws elbv2 describe-target-health --target-group-arn <ARN> --region us-east-1

# Test connectivity
curl -I http://LOADBALANCER_URL

# Check from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://guestbook-ui.default.svc.cluster.local
```

## Cost Considerations

### LoadBalancer Costs (us-east-1)

- **Classic Load Balancer**: ~$0.025/hour + $0.008/GB processed
- **Network Load Balancer**: ~$0.0225/hour + $0.006/GB processed
- **Application Load Balancer**: ~$0.0225/hour + $0.008/GB processed

### Cost Savings

- Use **port-forward** for development (free)
- Use **single LoadBalancer** with Ingress for multiple services
- Delete LoadBalancers when not in use

## Security Considerations

### Restrict Access by IP

```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/load-balancer-source-ranges: "1.2.3.4/32,5.6.7.8/32"
```

### Use Internal LoadBalancer for Private Services

```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internal
```

### Enable Access Logs

```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-access-log-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-name: "my-logs-bucket"
```

## References

- [Kubernetes Service Types](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Load Balancing](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html)

---

**Quick Fix:** If LoadBalancer isn't accessible, ensure it's internet-facing:

```yaml
annotations:
  service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```
