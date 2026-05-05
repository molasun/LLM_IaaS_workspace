terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.2.0"
}

# 從變數讀取 AWS 區域
provider "aws" {
  region = var.region
}

resource "aws_instance" "llm_server" {
  ami                    = var.ami # AMI ID (作業系統鏡像)
  instance_type          = var.instance_type # 執行實例規格
  key_name               = var.name # 金鑰 key pair 名稱
  vpc_security_group_ids = [aws_security_group.llm_server_sg.id] # 安全群組
  
  # 啟動腳本
  user_data = var.force_reload_user_data ? (
    <<-EOF
    #!/bin/bash
    # Force reload timestamp: ${timestamp()}
    ${file("files/setup-${var.os_version}.sh")}
    EOF
  ) : file("files/setup-${var.os_version}.sh")
  
  user_data_replace_on_change = false

  count                  = var.counts # 執行個體數量

  root_block_device {
    volume_size = var.volume # 根磁碟區大小 (GB)
  }

  tags = {
    Name = var.name # 執行個體名稱標籤
  }
}

resource "aws_key_pair" "llm_server_keypair" {
  key_name   = var.name # 金鑰 key pair 名稱
  public_key = var.ssh_public_key # 金鑰 public key
}

resource "aws_security_group" "llm_server_sg" {
  name = "${var.name}_sg" # 安全群組名稱

  ingress = [{
    description      = "Allow Dashboard"
    from_port        = 3000
    to_port          = 3001
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    },
    {
      description      = "Allow SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow HTTP"
      from_port        = 8000
      to_port          = 8000
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
  }]

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.name}_sg"
  }
}

output "public_dns" {
  description = "Public DNS names of the EC2 instances (accessible from the Internet)"
  value       = aws_instance.llm_server[*].public_dns # [*] 表示所有執行個體的 public_dns
}