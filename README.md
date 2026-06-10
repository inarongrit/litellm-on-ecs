# Deploy LiteLLM on AWS ECS

Deploy [LiteLLM](https://github.com/BerriAI/litellm) proxy on AWS ECS Fargate with full observability stack.

## Architecture

```
Internet → ALB (port 80) → ECS Fargate (port 4000) → LLM Providers
                                    ↓
                              PostgreSQL (RDS)
                                    ↓
                    Prometheus + Grafana (monitoring)
                    CloudWatch (logs)
```

**Components:**
- ECS Fargate — serverless container execution
- ECR — private Docker registry
- RDS PostgreSQL — stores keys, teams, spend tracking, enables UI
- ALB — load balancer with health checks
- Secrets Manager — API keys for LLM providers
- CloudWatch — container logs
- Amazon Managed Prometheus — metrics collection
- Amazon Managed Grafana — dashboards & visualization

## Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- [Terraform](https://www.terraform.io/) v1.0+
- [Docker](https://www.docker.com/) with buildx support
- AWS IAM Identity Center (SSO) enabled (for Grafana access)

### Required IAM Permissions

The user running Terraform needs access to: ECS, ECR, IAM, VPC/EC2, RDS, ELB, Secrets Manager, CloudWatch, Managed Prometheus, Managed Grafana.

## Quick Start

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region         = "ap-northeast-1"
aws_profile        = "default"
environment        = "dev"
availability_zones = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]

ecs_cpu       = 4096
ecs_memory    = 8192
desired_count = 1

db_instance_class  = "db.t3.micro"
db_username        = "litellm"
db_password        = "your-strong-password"

litellm_master_key = "sk-your-master-key"
litellm_salt_key   = "sk-your-salt-key"
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 3. Build & Push Docker Image

```bash
./build.sh <region> <profile>
# Example: ./build.sh ap-northeast-1 default
```

### 4. Update API Keys in Secrets Manager

```bash
aws secretsmanager put-secret-value \
  --secret-id litellm/dev/openai-api-key \
  --secret-string '{"OPENAI_API_KEY":"sk-your-real-key"}' \
  --region ap-northeast-1

aws secretsmanager put-secret-value \
  --secret-id litellm/dev/anthropic-api-key \
  --secret-string '{"ANTHROPIC_API_KEY":"sk-ant-your-real-key"}' \
  --region ap-northeast-1
```

Then force a redeployment to pick up new secrets:

```bash
aws ecs update-service --cluster litellm-dev-cluster \
  --service litellm-dev-service --force-new-deployment \
  --region ap-northeast-1
```

### 5. Access LiteLLM

After deployment, Terraform outputs the ALB DNS:

```bash
terraform output alb_dns
```

- **UI Dashboard:** `http://<alb_dns>/ui` (login with master key)
- **API:** `http://<alb_dns>/v1/chat/completions`
- **Health:** `http://<alb_dns>/health/liveliness`
- **Metrics:** `http://<alb_dns>/metrics`

## Configuration

### LiteLLM Models

Edit `config.yaml` to add/remove LLM providers:

```yaml
model_list:
  - model_name: claude-3-5-sonnet-latest
    litellm_params:
      model: anthropic/claude-3-5-sonnet-latest
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: gpt-5
    litellm_params:
      model: openai/gpt-5
      api_key: os.environ/OPENAI_API_KEY
```

### Multi-Environment Deployment

Resources are namespaced by `var.environment`. Deploy multiple environments in the same account:

```bash
# Dev
terraform workspace new dev
terraform apply -var="environment=dev"

# Prod
terraform workspace new prod
terraform apply -var="environment=prod" -var="ecs_cpu=8192" -var="ecs_memory=16384" -var="desired_count=3" -var="db_instance_class=db.r6g.large"
```

### Multi-Region Deployment

Change region and availability zones in `terraform.tfvars`:

```hcl
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

## How It Works

```
Cluster → Service → Task
```

- ECS Fargate runs the LiteLLM container
- Each environment gets its own cluster, service, and task definition
- ALB routes traffic and performs health checks
- RDS stores user/key/team data for the UI dashboard
- Prometheus callback exposes `/metrics` for monitoring

## Monitoring

- **CloudWatch Logs:** `/ecs/litellm-<environment>`
- **Prometheus Metrics:** `terraform output prometheus_endpoint`
- **Grafana Dashboard:** `terraform output grafana_endpoint`
- **LiteLLM Grafana Dashboards:** [github.com/BerriAI/litellm/grafana_dashboard](https://github.com/BerriAI/litellm/tree/main/cookbook/litellm_proxy_server/grafana_dashboard)

## Scaling

- **Horizontal:** Increase `desired_count` in tfvars
- **Vertical:** Adjust `ecs_cpu` and `ecs_memory`
- **Database:** Change `db_instance_class` (e.g., `db.r6g.large` for prod)

## Teardown

```bash
terraform destroy
```

## File Structure

```
├── provider.tf              # AWS provider config
├── variables.tf             # Input variables
├── outputs.tf               # Output values (ALB DNS, endpoints)
├── terraform.tfvars.example # Template for your variables
├── vpc.tf                   # VPC, subnets, ECS security group
├── ecs.tf                   # ECS cluster
├── ecr.tf                   # ECR repository
├── taskdefinition.tf        # ECS task definition
├── service.tf               # ECS service
├── alb.tf                   # Application Load Balancer
├── rds.tf                   # PostgreSQL database
├── iam.tf                   # IAM roles and policies
├── secrets.tf               # Secrets Manager for API keys
├── cloudwatch.tf            # CloudWatch log group
├── monitoring.tf            # Managed Prometheus + Grafana
├── config.yaml              # LiteLLM proxy configuration
├── Dockerfile               # Container image definition
├── build.sh                 # Build & deploy script
└── .gitignore
```
