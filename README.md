\# CloudCart Infrastructure



Infrastructure-as-Code repository for the CloudCart DevOps project.



This repository contains the Terraform configuration used to provision the AWS infrastructure required to run CloudCart on Amazon EKS.



CloudCart is a microservices-based application deployed through a CI/CD and GitOps workflow using Jenkins, Docker, Kubernetes, Argo CD, Prometheus, Grafana, Loki, and AWS.



\---



\## Project Overview



The CloudCart project is separated into three primary repositories:



\- `cloudcart-apps` - application source code, Dockerfiles, and Jenkins CI pipeline

\- `cloudcart-manifests` - Kubernetes manifests and Argo CD configuration

\- `cloudcart-infra` - Terraform infrastructure configuration



This repository is responsible specifically for the AWS infrastructure layer.



Terraform provisions the networking, security, IAM, Amazon EKS cluster, and managed worker node required by the platform.



\---



\## Infrastructure Architecture



The Terraform configuration provisions the following infrastructure:



1\. AWS VPC

2\. Two public subnets

3\. Internet Gateway

4\. Public route table

5\. Security group

6\. IAM roles and policies

7\. Amazon EKS cluster

8\. EKS managed node group



The infrastructure is deployed in the AWS `ap-south-1` region.



\---



\## AWS Networking



\### VPC



CloudCart uses a dedicated VPC with the following CIDR range:



```text

10.0.0.0/16

```



The VPC has DNS support and DNS hostnames enabled.



\### Public Subnets



Two public subnets are provisioned across separate Availability Zones.



| Subnet | CIDR | Availability Zone |

| --- | --- | --- |

| Public Subnet 1 | `10.0.1.0/24` | `ap-south-1a` |

| Public Subnet 2 | `10.0.2.0/24` | `ap-south-1b` |



Public IP assignment is enabled for instances launched inside these subnets.



The subnets are also tagged for Kubernetes and AWS load balancer integration.



\---



\## Internet Gateway



An Internet Gateway is attached to the CloudCart VPC.



A public route table contains the following route:



```text

0.0.0.0/0 -> Internet Gateway

```



Both public subnets are associated with this route table.



This provides outbound and inbound internet connectivity for resources deployed in the public subnets.



\---



\## Security Group



Terraform creates a security group named:



```text

cloudcart-sg

```



The current configuration allows inbound traffic on:



| Port | Protocol | Purpose |

| --- | --- | --- |

| 22 | TCP | SSH |

| 80 | TCP | HTTP |

| 443 | TCP | HTTPS |



Outbound traffic is allowed to all destinations.



The current SSH rule allows traffic from `0.0.0.0/0`. For a production environment, SSH access should be restricted to trusted IP ranges or replaced with a more secure administrative access method.



\---



\## Amazon EKS



CloudCart runs on Amazon Elastic Kubernetes Service.



The Terraform configuration creates an EKS cluster named:



```text

cloudcart-eks

```



The cluster uses both public subnets created by the VPC module.



Terraform also creates the IAM role required by the EKS control plane.



The following AWS managed policy is attached to the cluster role:



```text

AmazonEKSClusterPolicy

```



\---



\## EKS Managed Node Group



The EKS module provisions a managed worker node group named:



```text

cloudcart-workers

```



Current configuration:



| Setting | Value |

| --- | --- |

| Instance type | `t3.medium` |

| Desired nodes | 1 |

| Minimum nodes | 1 |

| Maximum nodes | 1 |



The node group runs across the public subnets created by the VPC module.



\---



\## Worker Node IAM Permissions



Terraform creates an IAM role for the EKS worker nodes.



The following AWS managed policies are attached:



\- `AmazonEKSWorkerNodePolicy`

\- `AmazonEKS\_CNI\_Policy`

\- `AmazonEC2ContainerRegistryReadOnly`



These permissions allow worker nodes to participate in the EKS cluster, use AWS VPC networking, and pull container images from Amazon ECR when required.



\---



\## Terraform Modules



The infrastructure is organized using reusable Terraform modules.



\### VPC Module



Responsible for:



\- VPC creation

\- Public subnet creation

\- Internet Gateway

\- Public route table

\- Route table associations

\- Kubernetes subnet tags



\### Security Group Module



Responsible for:



\- HTTP ingress

\- HTTPS ingress

\- SSH ingress

\- Outbound network access



\### EKS Module



Responsible for:



\- EKS cluster IAM role

\- EKS cluster

\- Worker node IAM role

\- IAM policy attachments

\- EKS managed node group



\---



\## Repository Structure



```text

cloudcart-infra/

|

|-- .gitignore

|

`-- terraform/

&#x20;   |-- main.tf

&#x20;   |-- provider.tf

&#x20;   |-- variables.tf

&#x20;   |-- outputs.tf

&#x20;   |-- .terraform.lock.hcl

&#x20;   |

&#x20;   `-- modules/

&#x20;       |-- vpc/

&#x20;       |   |-- main.tf

&#x20;       |   |-- variables.tf

&#x20;       |   `-- outputs.tf

&#x20;       |

&#x20;       |-- security-group/

&#x20;       |   |-- main.tf

&#x20;       |   |-- variables.tf

&#x20;       |   `-- outputs.tf

&#x20;       |

&#x20;       `-- eks/

&#x20;           |-- main.tf

&#x20;           |-- variables.tf

&#x20;           `-- outputs.tf

```



Terraform state files are intentionally excluded from Git through `.gitignore`.



\---



\## Terraform Provider



The project requires Terraform version 1.5.0 or newer.



The AWS provider is configured using the HashiCorp AWS provider version 5.x.



The infrastructure is deployed to:



```text

ap-south-1

```



\---



\## Root Terraform Configuration



The root Terraform configuration connects the three infrastructure modules.



```hcl

module "vpc" {

&#x20; source = "./modules/vpc"



&#x20; project\_name = "cloudcart"

&#x20; vpc\_cidr     = "10.0.0.0/16"

}



module "security\_group" {

&#x20; source = "./modules/security-group"



&#x20; vpc\_id = module.vpc.vpc\_id

}



module "eks" {

&#x20; source = "./modules/eks"



&#x20; cluster\_name = "cloudcart-eks"

&#x20; subnet\_ids   = module.vpc.public\_subnet\_ids

}

```



This creates a dependency chain where the security group depends on the VPC and the EKS cluster uses the subnets created by the VPC module.



\---



\## Terraform Outputs



The root Terraform configuration exposes the following outputs:



```text

vpc\_id

security\_group\_id

cluster\_name

cluster\_endpoint

```



These outputs provide useful information about the infrastructure after deployment.



\---



\## Deploying the Infrastructure



Before running Terraform, AWS credentials must be configured locally.



Navigate to the Terraform directory:



```bash

cd terraform

```



Initialize Terraform:



```bash

terraform init

```



Format the Terraform configuration:



```bash

terraform fmt -recursive

```



Validate the configuration:



```bash

terraform validate

```



Preview the infrastructure changes:



```bash

terraform plan

```



Provision the infrastructure:



```bash

terraform apply

```



Review the execution plan and confirm the deployment when prompted.



\---



\## Connecting kubectl to EKS



After the EKS cluster has been created, configure the local Kubernetes context:



```bash

aws eks update-kubeconfig --region ap-south-1 --name cloudcart-eks

```



Verify access to the cluster:



```bash

kubectl get nodes

```



A successful connection should display the EKS managed worker node.



\---



\## Destroying the Infrastructure



When the environment is no longer required, Terraform can remove the infrastructure:



```bash

terraform destroy

```



Always review the destruction plan before confirming.



Destroying temporary environments when they are no longer needed helps prevent unnecessary AWS charges.



\---



\## Terraform State



Terraform state files can contain infrastructure metadata and potentially sensitive information.



The repository therefore ignores:



```text

.terraform/

\*.tfstate

\*.tfstate.\*

terraform.tfvars

```



Terraform state files should not be committed to a public Git repository.



For a production environment, remote state storage with locking should be configured instead of relying only on local state.



\---



\## CloudCart Deployment Workflow



The complete CloudCart platform follows this workflow:



```text

Developer

&#x20; |

&#x20; v

cloudcart-apps

&#x20; |

&#x20; v

Jenkins CI

&#x20; |

&#x20; +-- Build container images with Kaniko

&#x20; |

&#x20; +-- Scan container images with Trivy

&#x20; |

&#x20; +-- Push container images

&#x20; |

&#x20; v

cloudcart-manifests

&#x20; |

&#x20; v

Argo CD

&#x20; |

&#x20; v

Amazon EKS

```



The infrastructure required by Amazon EKS is provisioned separately through this Terraform repository.



This separation keeps application development, Kubernetes deployment configuration, and infrastructure provisioning independently manageable.



\---



\## GitOps Architecture



CloudCart separates Continuous Integration from Continuous Deployment.



\### Continuous Integration



Jenkins handles the CI workflow.



Its responsibilities include:



\- Building application services

\- Building container images

\- Running container security scans

\- Publishing container images

\- Updating deployment image versions



\### Continuous Deployment



Argo CD handles Kubernetes deployment through GitOps.



Argo CD monitors the `cloudcart-manifests` repository and synchronizes the desired Kubernetes configuration with the EKS cluster.



This creates a Git-based source of truth for application deployment.



\---



\## Infrastructure Lifecycle



The infrastructure lifecycle follows a standard Terraform workflow:



```text

terraform init

terraform fmt

terraform validate

terraform plan

terraform apply

```



After provisioning, AWS CLI and kubectl are used to configure access to the EKS cluster.



Application workloads are then deployed through Argo CD rather than directly through Terraform.



\---



\## Technologies Used



| Technology | Purpose |

| --- | --- |

| Terraform | Infrastructure as Code |

| AWS | Cloud infrastructure |

| Amazon VPC | Network isolation |

| Amazon EKS | Managed Kubernetes |

| AWS IAM | Identity and access management |

| EC2 | EKS worker node compute |

| Kubernetes | Container orchestration |

| Argo CD | GitOps deployment |

| Jenkins | Continuous Integration |

| Kaniko | Container image builds |

| Trivy | Container security scanning |

| Prometheus | Metrics collection |

| Grafana | Monitoring and visualization |

| Loki | Centralized logging |

| Git | Version control |

| GitHub | Source code hosting |



\---



\## Key DevOps Concepts Demonstrated



This infrastructure project demonstrates practical experience with:



\- Infrastructure as Code

\- Terraform modules

\- AWS networking

\- VPC architecture

\- IAM roles and policies

\- Amazon EKS

\- Kubernetes infrastructure

\- Managed worker nodes

\- Infrastructure dependency management

\- GitOps architecture

\- CI/CD separation

\- Containerized workloads

\- Infrastructure lifecycle management

\- Cloud resource provisioning

\- Git-based infrastructure version control



\---



\## Related Repositories



The complete CloudCart project is divided into three repositories.



\### cloudcart-apps



Contains:



\- Node.js microservices

\- Dockerfiles

\- Jenkins pipeline

\- Container build configuration

\- CI workflow



\### cloudcart-manifests



Contains:



\- Kubernetes Deployments

\- Kubernetes Services

\- NGINX Ingress configuration

\- Argo CD Application configuration

\- GitOps deployment manifests



\### cloudcart-infra



Contains:



\- Terraform configuration

\- VPC module

\- Security group module

\- EKS module

\- IAM configuration

\- AWS infrastructure definitions



Together, these repositories represent the complete CloudCart DevOps platform.



\---



\## Current Infrastructure Configuration



The current Terraform implementation provisions:



\- One VPC

\- Two public subnets

\- One Internet Gateway

\- One public route table

\- One security group

\- EKS control plane IAM role

\- Worker node IAM role

\- Amazon EKS cluster

\- One EKS managed node group

\- One `t3.medium` worker node



The configuration is designed as a learning and portfolio environment demonstrating AWS, Terraform, Kubernetes, CI/CD, and GitOps concepts.



\---



\## Author



\*\*Somil Mor\*\*



B.Tech Electronics and Communication Engineering



DevOps and Cloud Engineering



Core technologies:



`AWS` `Terraform` `Linux` `Docker` `Kubernetes` `Jenkins` `Argo CD` `Git` `GitHub` `Prometheus` `Grafana` `Loki`

