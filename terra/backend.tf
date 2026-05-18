terraform {
  backend "s3" {
    bucket = "secure-cicd-terraform-state-201727487182"
    key    = "secure-cicd/terraform.tfstate"
    region = "ap-southeast-2"
  }
}