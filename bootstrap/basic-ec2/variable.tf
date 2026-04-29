variable "name" {
  type    = string
  default = "tool_server"
}

# ap-southeast-2: RHEL 9 - ami-09ddda64620c9840e
# ap-southeast-2: Ubuntu 24.04 - ami-0c33c6bd24cee108b
# us-east-2: RHEL 9 - ami-08d2f096f70b3dd74
# us-east-2: Ubuntu 24.04 - ami-07062e2a343acc423
variable "ami" {
  type    = string
  default = "ami-09ddda64620c9840e"
}

# Option rhel9, ubuntu2404
variable "os_version" {
  type = string
  default = "rhel9"
}

# g6.4xlarge - L4
# g6e.4xlarge - L40S
# m5.2xlarge - 8/32
variable "instance_type" {
  type    = string
  default = "m5.2xlarge"
}

variable "ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCmNv5ir0tyFg2t2kQTzra5yeHs9ANIeceX15cTG9Ng74o1qM2Vc5vSvV5T5Ah4WBnapFEzy7qHHncm5q+MgSLOMjaxlFdJTinHa/Jsg5GHMIS1f7Nl+2+XtBQXOgKvarZq7i4A/H0fYsaw2bUUARlAg4C/ioPbxbKr27hYEloo7sf131WS62RVKYJyyIoKoPCnAR0xuANJ73DzDxKzbVbRym26tpO1rfPs6NSlSXhASLA78lvW2uZuZuFRLgExj8SJq46bANw9hkRmgTyGsOvkz3lzcodjP6iL/CTVmNaHq24qxu3m3WvzCuGTDHj536JaquWXpV1TpucaBKpRRpSq9ybdBcjXGsT9qK+JEiz//6rDNZZSwgh4Lf/PKNn90wRwKtL5yPRVTxfIkHwu6BxoN8raGTfQGaOLP15fCkqTAInJA47fnJvLGDVFFlfepHKRJMH9d6bbbZUqyvNDqWY25iSb237kyaaCqEEUoFdKGRX+DPlgQA6se1AmkjX/VgUM+HxZfAHGebvJCEJT29FwRCQ7iQtTlrkrIypd4n+DD2y1uWVWZ36wIt19Yj4qsixzlW/6TxEPg+TC3zI0ucbIy58LM5ahrLLNoU3nJ/x2xJJRFW65soGaXA9fHy4r0bWOQpVy7pEJOvoDNOo+v7Pu2Fu7KpNTrrsRt6r5fISpWw== ysuen@redhat.com"
}

# us-east-2
# ap-southeast-2
variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "counts" {
  type    = number
  default = 2
}

variable "volume" {
  type    = number
  default = 100
}