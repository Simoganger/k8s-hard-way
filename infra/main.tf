# ---------- Debian 12 (bookworm) AMI, amd64, published by the Debian project ----------
data "aws_ami" "debian12" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------- SSH key pair (generated locally, private key written to infra/) ----------
resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "this" {
  key_name   = "k8s-hard-way"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = "${path.module}/k8s-hard-way.pem"
  file_permission = "0600"
}

# ---------- Network ----------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "k8s-hard-way" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "k8s-hard-way" }
}

resource "aws_subnet" "this" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = { Name = "k8s-hard-way" }
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "k8s-hard-way" }
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}

resource "aws_security_group" "this" {
  name        = "k8s-hard-way"
  description = "Kubernetes the hard way machines"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "k8s-hard-way" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.this.id
  description       = "SSH"
  cidr_ipv4         = var.ssh_allowed_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "api" {
  security_group_id = aws_security_group.this.id
  description       = "Kubernetes API server"
  cidr_ipv4         = var.ssh_allowed_cidr
  ip_protocol       = "tcp"
  from_port         = 6443
  to_port           = 6443
}

resource "aws_vpc_security_group_ingress_rule" "internal" {
  security_group_id            = aws_security_group.this.id
  description                  = "All traffic between the machines"
  referenced_security_group_id = aws_security_group.this.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------- Machines ----------
resource "aws_instance" "machine" {
  for_each = var.machines

  ami                    = data.aws_ami.debian12.id
  instance_type          = each.value.instance_type
  subnet_id              = aws_subnet.this.id
  private_ip             = each.value.private_ip
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.this.id]

  # The tutorial routes pod CIDRs between nodes by hand, which requires
  # the instances to forward packets not addressed to them.
  source_dest_check = false

  root_block_device {
    volume_size = each.value.disk_size_gb
    volume_type = "gp3"
  }

  tags = { Name = each.key }
}
