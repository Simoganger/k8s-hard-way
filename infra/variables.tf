variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH and to reach the Kubernetes API (6443). Restrict it to your public IP, e.g. 203.0.113.4/32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpc_cidr" {
  description = "CIDR of the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR of the public subnet hosting the 4 machines."
  type        = string
  default     = "10.0.1.0/24"
}

# Sizes follow the tutorial requirements:
#   jumpbox: 1 vCPU / 512MB / 10GB       --> t3.nano  = 2 vCPU / 0.5GB
#   server, node-*: 1 vCPU / 2GB / 20GB  --> t3.small = 2 vCPU / 2GB (AWS has no 1 vCPU burstable size).
variable "machines" {
  description = "Machines to create."
  type = map(object({
    instance_type = string
    disk_size_gb  = number
    private_ip    = string
  }))
  default = {
    jumpbox = { instance_type = "t3.nano", disk_size_gb = 10, private_ip = "10.0.1.10" }
    server  = { instance_type = "t3.small", disk_size_gb = 20, private_ip = "10.0.1.11" }
    node-0  = { instance_type = "t3.small", disk_size_gb = 20, private_ip = "10.0.1.20" }
    node-1  = { instance_type = "t3.small", disk_size_gb = 20, private_ip = "10.0.1.21" }
  }
}
