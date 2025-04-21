# main.tf

provider "aws" {
  region = var.region
}

############
# VPC Setup #
############
resource "aws_vpc" "this" {
  cidr_block       = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "prod-eks-vpc"
  }
}

resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "prod-eks-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "prod-public-rt"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_subnet_assoc" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

################
# EKS Creation #
################
resource "aws_eks_cluster" "this" {
  name     = "prod-eks-cluster"
  role_arn = var.eks_role_arn

  vpc_config {
    subnet_ids         = concat(
      [for s in aws_subnet.private_subnets : s.id],
      [for s in aws_subnet.public_subnets : s.id]
    )
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  version = var.eks_version

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]
}

resource "aws_eks_node_group" "this" {
  depends_on = [aws_eks_cluster.this]

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "prod-eks-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = [for s in aws_subnet.private_subnets : s.id]

  scaling_config {
    desired_size = 2000
    max_size     = 2000
    min_size     = 1
  }
}

##########################
# RDS Subnet Group Setup #
##########################
resource "aws_db_subnet_group" "this" {
  name       = "prod-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private_subnets : s.id]

  tags = {
    Name = "prod-db-subnet-group"
  }
}

######################
# 10 RDS Instances   #
######################
locals {
  db_names = [
    for i in range(1, 11) : "prod-db-${i}"
  ]
}

resource "aws_db_instance" "this" {
  for_each                    = toset(local.db_names)
  identifier                  = each.value
  allocated_storage           = 20
  engine                      = var.db_engine
  instance_class              = var.db_instance_type
  username                    = var.db_username
  password                    = var.db_password
  db_subnet_group_name        = aws_db_subnet_group.this.name
  skip_final_snapshot         = true
  publicly_accessible         = false
  multi_az                    = false
  deletion_protection         = false
  storage_encrypted           = true
  backup_retention_period     = 7
  backup_window               = "02:00-03:00"
  maintenance_window          = "mon:03:00-mon:04:00"
  vpc_security_group_ids      = [var.db_security_group_id]
  apply_immediately           = true
  tags = {
    Name = each.value
  }
}
