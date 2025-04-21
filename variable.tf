# variables.tf

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "eks_role_arn" {
  type        = string
  description = "IAM role ARN for the EKS control plane"
}

variable "node_role_arn" {
  type        = string
  description = "IAM role ARN for the EKS node group"
}

variable "eks_version" {
  type    = string
  default = "1.27"
}

variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_instance_type" {
  type    = string
  default = "db.t3.medium"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type        = string
  description = "DB master password"
  sensitive   = true
  default     = "ChangeThisPassword123!"
}

variable "db_security_group_id" {
  type        = string
  description = "Security Group ID to allow DB traffic"
}
