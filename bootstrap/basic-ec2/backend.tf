terraform {
  backend "s3" {
    bucket         = "llm-iaas"
    key            = "basic-ec2/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}