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

# 從變數讀取 bucket 名稱
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  tags = {
    Name        = "terraform-state"
    Environment = "bootstrap"
  }
}

# 啟用 S3 bucket 的版本控制功能
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 對 S3 bucket 中的所有檔案進行加密
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 全面封鎖 S3 bucket 的公開訪問
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}

# 建立 DynamoDB 表格用於狀態鎖定
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    Environment = "bootstrap"
  }
}

# 建立 AWS 預設 VPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# 輸出建立好的資源名稱
output "s3_bucket" {
  value = aws_s3_bucket.terraform_state.bucket
}

# 輸出建立好的資源名稱
output "dynamodb_table" {
  value = aws_dynamodb_table.terraform_locks.name
}