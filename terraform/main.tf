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

  subnet_ids = module.vpc.public_subnet_ids
}