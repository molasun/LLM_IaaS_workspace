terraform {
  backend "s3" {
    bucket         = "ai-iaas-01"
    key            = "gpu-ec2/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}