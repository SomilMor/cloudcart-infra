\# CloudCart Infrastructure — AWS EKS with Terraform



Infrastructure as Code for the \*\*CloudCart Production-Style DevOps Platform\*\*.



This repository contains the Terraform configuration used to provision the core AWS infrastructure required to run CloudCart on \*\*Amazon Elastic Kubernetes Service (EKS)\*\*.



The infrastructure is organized into reusable Terraform modules for networking, security, and Kubernetes infrastructure.



\---



\## Infrastructure Overview



```text

&#x20;                        AWS Cloud

&#x20;                           |

&#x20;                           v

&#x20;                 +-------------------+

&#x20;                 |   CloudCart VPC   |

&#x20;                 |    10.0.0.0/16    |

&#x20;                 +---------+---------+

&#x20;                           |

&#x20;              +------------+------------+

&#x20;              |                         |

&#x20;              v                         v

&#x20;      Public Subnet 1             Public Subnet 2

&#x20;       10.0.1.0/24                 10.0.2.0/24

&#x20;      ap-south-1a                  ap-south-1b

&#x20;              |                         |

&#x20;              +------------+------------+

&#x20;                           |

&#x20;                           v

&#x20;                 +-------------------+

&#x20;                 |    Amazon EKS     |

&#x20;                 |   cloudcart-eks   |

&#x20;                 +---------+---------+

&#x20;                           |

&#x20;                           v

&#x20;                 +-------------------+

&#x20;                 | EKS Managed Node  |

&#x20;                 |      Group        |

&#x20;                 |    t3.medium      |

&#x20;                 +-------------------+

```



The VPC contains two public subnets distributed across separate Availability Zones in the \*\*Mumbai (`ap-south-1`) AWS region\*\*.



An Internet Gateway and public route table provide internet connectivity to resources deployed within the public subnets.



\---



\## Tech Stack



| Technology | Purpose |

|---|---|

| Terraform | Infrastructure as Code |

| AWS | Cloud infrastructure |

| Amazon VPC | Network isolation |

| Amazon EKS | Managed Kubernetes control plane |

| Amazon EC2 | EKS worker node compute |

| AWS IAM | Cluster and worker-node permissions |

| AWS Security Groups | Network access rules |

| Git | Infrastructure version control |

| GitHub | Source-code hosting |



\---



\## Repository Structure



```text

cloudcart-infra/

|

+-- .gitignore

|

+-- terraform/

&#x20;   |

&#x20;   +-- main.tf

&#x20;   +-- provider.tf

&#x20;   +-- variables.tf

&#x20;   +-- outputs.tf

&#x20;   +-- .terraform.lock.hcl

&#x20;   |

&#x20;   +-- modules/

&#x20;       |

&#x20;       +-- vpc/

&#x20;       |   +-- main.tf

&#x20;       |   +-- variables.tf

&#x20;       |   +-- outputs.tf

&#x20;       |

&#x20;       +-- security-group/

&#x20;       |   +-- main.tf

&#x20;       |   +-- variables.tf

&#x20;       |   +-- outputs.tf

&#x20;       |

&#x20;       +-- eks/

&#x20;           +-- main.tf

&#x20;           +-- variables.tf

&#x20;           +-- outputs.tf

```



Terraform state files and local Terraform working files are excluded from Git through `.gitignore`.



\---



\## Terraform Architecture



The root Terraform configuration connects three infrastructure modules:



```text

Root Terraform Configuration

&#x20;         |

&#x20;         +---- VPC Module

&#x20;         |

&#x20;         +---- Security Group Module

&#x20;         |

&#x20;         +---- EKS Module

```



This modular structure separates infrastructure responsibilities and makes the configuration easier to understand and maintain.



\---



\## VPC Module



The VPC module creates the networking foundation for CloudCart.



\### VPC



```text

CIDR: 10.0.0.0/16

DNS Support: Enabled

DNS Hostnames: Enabled

```



The VPC is tagged as part of the CloudCart project.



\### Public Subnets



Two public subnets are provisioned across separate AWS Availability Zones.



```text

cloudcart-public-1

CIDR: 10.0.1.0/24

Availability Zone: ap-south-1a



cloudcart-public-2

CIDR: 10.0.2.0/24

Availability Zone: ap-south-1b

```



Public IP assignment is enabled for instances launched within these subnets.



The subnets also contain Kubernetes tags allowing AWS/Kubernetes integrations to recognize them for load-balancer usage.



\---



\## Internet Connectivity



The VPC module provisions an \*\*Internet Gateway\*\*:



```text

cloudcart-igw

```



A public route table contains the following route:



```text

Destination: 0.0.0.0/0

Target: Internet Gateway

```



Both public subnets are associated with this route table.



The resulting network path is:



```text

Internet

&#x20;  |

&#x20;  v

Internet Gateway

&#x20;  |

&#x20;  v

Public Route Table

&#x20;  |

&#x20;  +---- Public Subnet 1

&#x20;  |

&#x20;  +---- Public Subnet 2

```



\---



\## Security Group



A reusable security-group module creates:



```text

cloudcart-sg

```



The current configuration contains inbound rules for:



| Port | Protocol | Purpose |

|---|---|---|

| 22 | TCP | SSH |

| 80 | TCP | HTTP |

| 443 | TCP | HTTPS |



Outbound traffic is allowed to:



```text

0.0.0.0/0

```



The module outputs the generated Security Group ID for use by other infrastructure components when required.



> Note: The current Terraform configuration provisions this security group as a separate infrastructure component. It is not explicitly attached to the EKS cluster or managed node group by the current module configuration.



\---



\## Amazon EKS



The EKS module provisions the Kubernetes infrastructure used by CloudCart.



The cluster is created as:



```text

Cluster Name: cloudcart-eks

```



The cluster uses the two VPC public subnets:



```text

10.0.1.0/24

10.0.2.0/24

```



This distributes the cluster networking across:



```text

ap-south-1a

ap-south-1b

```



\---



\## EKS IAM Role



Terraform creates a dedicated IAM role for the EKS control plane.



The trust relationship allows:



```text

eks.amazonaws.com

```



to assume the role.



The following AWS-managed policy is attached:



```text

AmazonEKSClusterPolicy

```



This provides the permissions required by the EKS control plane.



\---



\## EKS Managed Node Group



CloudCart uses an EKS managed node group:



```text

cloudcart-workers

```



The node group configuration is:



```text

Desired Nodes: 1

Minimum Nodes: 1

Maximum Nodes: 1



Instance Type: t3.medium

```



The node is deployed into the VPC subnets provided by the networking module.



For this project, the node group is intentionally small to keep the infrastructure suitable for a learning and portfolio environment.



\---



\## Worker Node IAM Permissions



A separate IAM role is created for the EKS worker node.



The role can be assumed by:



```text

ec2.amazonaws.com

```



Terraform attaches the following AWS-managed policies:



```text

AmazonEKSWorkerNodePolicy

AmazonEKS\_CNI\_Policy

AmazonEC2ContainerRegistryReadOnly

```



These permissions allow the worker node to:



\- Operate as part of the EKS cluster

\- Use AWS VPC networking through the EKS CNI

\- Pull container images from Amazon ECR when required



\---



\## Terraform Module Dependencies



The infrastructure modules are connected using Terraform outputs.



```text

VPC Module

&#x20;   |

&#x20;   +---- vpc\_id ----------------+

&#x20;   |                            |

&#x20;   |                            v

&#x20;   |                    Security Group

&#x20;   |

&#x20;   +---- public\_subnet\_ids

&#x20;                |

&#x20;                v

&#x20;            EKS Module

```



The VPC module exposes the VPC ID and subnet IDs.



The root configuration passes:



```text

module.vpc.vpc\_id

```



to the security-group module and:



```text

module.vpc.public\_subnet\_ids

```



to the EKS module.



\---



\## Terraform Outputs



After infrastructure provisioning, Terraform exposes several useful values.



\### VPC ID



```text

vpc\_id

```



Returns the ID of the CloudCart VPC.



\### Security Group ID



```text

security\_group\_id

```



Returns the ID of the CloudCart security group.



\### EKS Cluster Name



```text

cluster\_name

```



Returns:



```text

cloudcart-eks

```



\### EKS Cluster Endpoint



```text

cluster\_endpoint

```



Returns the Kubernetes API endpoint generated by Amazon EKS.



\---



\## Deploying the Infrastructure



Terraform commands should be executed from:



```text

cloudcart-infra/terraform

```



Initialize Terraform:



```bash

terraform init

```



Validate the configuration:



```bash

terraform validate

```



Review the infrastructure changes:



```bash

terraform plan

```



Provision the infrastructure:



```bash

terraform apply

```



Terraform will display the resources that will be created and request confirmation before applying the configuration.



\---



\## Connecting kubectl to EKS



After the EKS cluster has been created, the local Kubernetes configuration can be updated using the AWS CLI:



```bash

aws eks update-kubeconfig --region ap-south-1 --name cloudcart-eks

```



Cluster connectivity can then be verified with:



```bash

kubectl get nodes

```



and:



```bash

kubectl get pods -A

```



\---



\## Terraform State Management



Terraform state contains information about provisioned infrastructure and should not be committed to a public Git repository.



The repository `.gitignore` excludes:



```text

.terraform/

\*.tfstate

\*.tfstate.\*

terraform.tfvars

```



This prevents local state files and variable files from accidentally being committed.



The current project uses locally stored Terraform state.



For a production environment, Terraform state would typically be moved to an appropriate remote backend with suitable state locking and access controls.



\---



\## Infrastructure Lifecycle



The Terraform workflow follows:



```text

Terraform Configuration

&#x20;       |

&#x20;       v

terraform init

&#x20;       |

&#x20;       v

terraform validate

&#x20;       |

&#x20;       v

terraform plan

&#x20;       |

&#x20;       v

terraform apply

&#x20;       |

&#x20;       v

AWS Infrastructure

&#x20;       |

&#x20;       +---- VPC

&#x20;       +---- Public Subnets

&#x20;       +---- Internet Gateway

&#x20;       +---- Route Table

&#x20;       +---- Security Group

&#x20;       +---- IAM Roles

&#x20;       +---- Amazon EKS

&#x20;       +---- Managed Node Group

```



Terraform provides a repeatable and version-controlled definition of the core CloudCart AWS infrastructure.



\---



\## CloudCart DevOps Architecture



This repository represents the \*\*Infrastructure as Code layer\*\* of the wider CloudCart project.



CloudCart is separated into multiple repositories based on responsibility:



```text

cloudcart-infra

&#x20;     |

&#x20;     | Terraform provisions AWS infrastructure

&#x20;     v

Amazon EKS

&#x20;     ^

&#x20;     |

&#x20;     | Argo CD deploys Kubernetes manifests

&#x20;     |

cloudcart-manifests

&#x20;     ^

&#x20;     |

&#x20;     | Jenkins updates application image tags

&#x20;     |

cloudcart-apps

```



\### cloudcart-infra



Responsible for:



\- AWS VPC

\- Public subnets

\- Internet Gateway

\- Route tables

\- Security group

\- EKS cluster

\- EKS managed node group

\- IAM roles and policy attachments



\### cloudcart-apps



Contains the CloudCart application microservices and the CI pipeline responsible for building and scanning container images.



\### cloudcart-manifests



Contains the Kubernetes manifests consumed by Argo CD for GitOps-based application deployment.



\---



\## End-to-End Platform Flow



Together, the CloudCart repositories demonstrate the following workflow:



```text

Developer

&#x20;   |

&#x20;   v

GitHub

&#x20;   |

&#x20;   v

Jenkins CI

&#x20;   |

&#x20;   +---- Build containers with Kaniko

&#x20;   |

&#x20;   +---- Scan images with Trivy

&#x20;   |

&#x20;   +---- Push container images

&#x20;   |

&#x20;   v

cloudcart-manifests

&#x20;   |

&#x20;   v

Argo CD

&#x20;   |

&#x20;   v

Amazon EKS

&#x20;   |

&#x20;   v

CloudCart Microservices

```



The AWS infrastructure supporting this workflow is defined and managed through this Terraform repository.



\---



\## Key Infrastructure Concepts Demonstrated



This project demonstrates practical experience with:



\- Infrastructure as Code

\- Terraform modules

\- AWS networking

\- VPC design

\- Multi-AZ subnet deployment

\- Internet Gateway configuration

\- Route tables

\- AWS IAM roles

\- IAM policy attachments

\- Amazon EKS

\- EKS managed node groups

\- Kubernetes infrastructure

\- Terraform outputs

\- Terraform dependency management

\- Infrastructure version control

\- Separation of infrastructure, application, and deployment configuration



\---



\## Security Considerations



The repository avoids committing Terraform state and variable files through `.gitignore`.



The current security group allows SSH, HTTP, and HTTPS from:



```text

0.0.0.0/0

```



This configuration is suitable for demonstrating infrastructure concepts in a temporary project environment, but production environments should restrict administrative access such as SSH to trusted networks or use managed access mechanisms.



Infrastructure secrets and credentials should never be stored directly inside Terraform source files or committed to Git.



\---



\## Project Purpose



CloudCart was built as a hands-on DevOps project demonstrating how multiple technologies can be integrated into a complete deployment lifecycle.



The infrastructure repository specifically demonstrates how \*\*Terraform can be used to provision the AWS and EKS foundation\*\* on which the rest of the DevOps platform operates.



Rather than manually creating cloud resources, the infrastructure is represented as version-controlled Terraform code.



\---



\## Related Repositories



The CloudCart project is split into three primary repositories:



```text

cloudcart-apps

Application source code and CI pipeline



cloudcart-manifests

Kubernetes manifests and Argo CD GitOps configuration



cloudcart-infra

Terraform AWS infrastructure

```



Together they represent the separation of:



```text

Application

&#x20;    +

Continuous Integration

&#x20;    +

Infrastructure as Code

&#x20;    +

GitOps

&#x20;    +

Kubernetes

&#x20;    +

Observability

```



\---



\## Author



\*\*Somil Mor\*\*



B.Tech Electronics and Communication Engineering



DevOps-focused engineering project demonstrating practical experience with AWS, Terraform, Docker, Kubernetes, Jenkins, Argo CD, GitOps, Prometheus, Grafana and Loki.

