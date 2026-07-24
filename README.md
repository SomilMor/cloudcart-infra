# CloudCart Infrastructure

Terraform-based AWS infrastructure for the CloudCart DevOps platform.

This repository contains the Infrastructure as Code used to provision the AWS networking and Amazon EKS environment for CloudCart.

## Project Overview

CloudCart is a cloud-native microservices project designed to demonstrate an end-to-end DevOps workflow on AWS.

The project is separated into three repositories:

- `cloudcart-apps` contains application services, Dockerfiles, and the Jenkins CI pipeline.
- `cloudcart-manifests` contains Kubernetes manifests and the Argo CD application configuration.
- `cloudcart-infra` contains Terraform configuration for AWS infrastructure.

This repository represents the infrastructure layer.

## Infrastructure Provisioned

Terraform provisions:

- One VPC
- Two public subnets
- Internet Gateway
- Public route table and subnet associations
- Security group
- IAM role for the EKS control plane
- IAM role for EKS worker nodes
- Amazon EKS cluster
- EKS managed node group

The infrastructure is deployed in AWS region `ap-south-1`.

## AWS Networking

### VPC

The CloudCart VPC uses:

```text
10.0.0.0/16
```

DNS support and DNS hostnames are enabled.

### Public Subnets

| Subnet | CIDR | Availability Zone |
| --- | --- | --- |
| Public Subnet 1 | `10.0.1.0/24` | `ap-south-1a` |
| Public Subnet 2 | `10.0.2.0/24` | `ap-south-1b` |

Public IP assignment is enabled on both subnets.

The subnets also contain Kubernetes tags for EKS and load balancer integration.

### Internet Gateway

An Internet Gateway is attached to the VPC.

The public route table provides a default route through the Internet Gateway, and both public subnets are associated with that route table.

## Security Group

Terraform creates `cloudcart-sg`.

Current inbound rules:

| Port | Protocol | Purpose |
| --- | --- | --- |
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |

Outbound traffic is allowed to all destinations.

The current SSH rule allows access from all IPv4 addresses. In a production environment, administrative access should be restricted to trusted sources.

## Amazon EKS

The Kubernetes environment runs on Amazon Elastic Kubernetes Service.

Cluster name:

```text
cloudcart-eks
```

The cluster uses both public subnets created by the VPC module.

Terraform creates the IAM role required by the EKS control plane and attaches `AmazonEKSClusterPolicy`.

## EKS Managed Node Group

Terraform creates a managed node group named:

```text
cloudcart-workers
```

| Setting | Value |
| --- | --- |
| Instance type | `t3.medium` |
| Desired size | 1 |
| Minimum size | 1 |
| Maximum size | 1 |

The worker node IAM role uses:

- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`

## Terraform Modules

### VPC Module

Responsible for:

- VPC creation
- Public subnets
- Internet Gateway
- Public route table
- Route table associations
- Kubernetes subnet tags

Files:

- `terraform/modules/vpc/main.tf`
- `terraform/modules/vpc/variables.tf`
- `terraform/modules/vpc/outputs.tf`

### Security Group Module

Responsible for the CloudCart network security rules.

Files:

- `terraform/modules/security-group/main.tf`
- `terraform/modules/security-group/variables.tf`
- `terraform/modules/security-group/outputs.tf`

### EKS Module

Responsible for:

- EKS control plane IAM role
- Amazon EKS cluster
- Worker node IAM role
- IAM policy attachments
- EKS managed node group

Files:

- `terraform/modules/eks/main.tf`
- `terraform/modules/eks/variables.tf`
- `terraform/modules/eks/outputs.tf`

## Repository Structure

Main repository contents:

- `.gitignore`
- `terraform/main.tf`
- `terraform/provider.tf`
- `terraform/variables.tf`
- `terraform/outputs.tf`
- `terraform/.terraform.lock.hcl`
- `terraform/modules/vpc`
- `terraform/modules/security-group`
- `terraform/modules/eks`

Terraform state files are excluded from Git.

## Root Terraform Configuration

The root configuration connects the infrastructure modules.

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name = "cloudcart"
  vpc_cidr     = "10.0.0.0/16"
}

module "security_group" {
  source = "./modules/security-group"

  vpc_id = module.vpc.vpc_id
}

module "eks" {
  source = "./modules/eks"

  cluster_name = "cloudcart-eks"
  subnet_ids   = module.vpc.public_subnet_ids
}
```

The security group depends on the VPC ID, while the EKS module receives the public subnet IDs from the VPC module.

## Terraform Requirements

The project requires Terraform 1.5.0 or newer.

The AWS provider uses the HashiCorp AWS provider version 5.x.

AWS region:

```text
ap-south-1
```

## Terraform Outputs

The root configuration exposes:

- `vpc_id`
- `security_group_id`
- `cluster_name`
- `cluster_endpoint`

## Deploying the Infrastructure

Navigate to the Terraform directory:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt -recursive
```

Validate it:

```bash
terraform validate
```

Preview changes:

```bash
terraform plan
```

Provision the infrastructure:

```bash
terraform apply
```

Review the Terraform plan before confirming.

## Connecting to Amazon EKS

After the cluster is created:

```bash
aws eks update-kubeconfig --region ap-south-1 --name cloudcart-eks
```

Verify access:

```bash
kubectl get nodes
```

## Terraform State

The repository ignores:

```text
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
```

Terraform state should not be committed to a public repository.

For a production environment, remote state storage with locking would be preferable to local state.

## CI/CD and GitOps Integration

CloudCart separates Continuous Integration from Continuous Deployment.

### Continuous Integration

Jenkins handles:

- Application builds
- Container image builds with Kaniko
- Container security scanning with Trivy
- Container image publishing
- GitOps manifest image tag updates

### Continuous Deployment

Argo CD handles Kubernetes deployment.

The `cloudcart-manifests` repository acts as the GitOps source of truth. Argo CD synchronizes the desired Kubernetes configuration with Amazon EKS.

## Infrastructure Lifecycle

Typical Terraform workflow:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

When the environment is no longer required:

```bash
terraform destroy
```

Review the destruction plan before confirming.

## Technology Stack

| Technology | Purpose |
| --- | --- |
| AWS | Cloud platform |
| Terraform | Infrastructure as Code |
| Amazon VPC | Networking |
| Amazon EKS | Managed Kubernetes |
| AWS IAM | Roles and permissions |
| EC2 | Worker compute |
| Kubernetes | Container orchestration |
| Jenkins | Continuous Integration |
| Kaniko | Container image builds |
| Trivy | Container security scanning |
| Argo CD | GitOps deployment |
| Prometheus | Metrics |
| Grafana | Monitoring |
| Loki | Centralized logging |
| Git | Version control |
| GitHub | Repository hosting |

## DevOps Concepts Demonstrated

This project demonstrates:

- Infrastructure as Code
- Terraform modules
- AWS networking
- IAM roles and policies
- Amazon EKS
- Kubernetes infrastructure
- Managed worker nodes
- Infrastructure dependencies
- CI/CD
- GitOps
- Container security scanning
- Monitoring and observability
- Infrastructure lifecycle management

## Related Repositories

### cloudcart-apps

Contains:

- Node.js microservices
- Dockerfiles
- Jenkins pipeline
- Kaniko container builds
- Trivy scanning

### cloudcart-manifests

Contains:

- Kubernetes Deployments
- Kubernetes Services
- NGINX Ingress
- Argo CD Application configuration

### cloudcart-infra

Contains:

- Terraform configuration
- VPC resources
- Public subnets
- Security group
- IAM roles
- Amazon EKS
- Managed node group

Together, these repositories demonstrate the CloudCart workflow from infrastructure provisioning through CI and GitOps deployment.

## Current Project Scope

The current Terraform implementation provisions:

- One VPC
- Two public subnets
- One Internet Gateway
- One public route table
- One security group
- EKS control plane IAM resources
- Worker node IAM resources
- One Amazon EKS cluster
- One managed node group
- One `t3.medium` worker node

The project is intended as a portfolio and learning environment demonstrating AWS, Terraform, Kubernetes, CI/CD, GitOps, security scanning, monitoring, and logging.

## Author

**Somil Mor**

B.Tech Electronics and Communication Engineering

DevOps and Cloud Engineering

Core technologies: AWS, Terraform, Linux, Docker, Kubernetes, Jenkins, Argo CD, Git, GitHub, Prometheus, Grafana, and Loki.
