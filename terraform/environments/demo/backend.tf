terraform {
  backend "s3" {
    bucket = "jamf-eks-hw-terraform-state"
    key    = "jamf-demo/terraform.tfstate"
    region = "us-east-2"
  }
}
