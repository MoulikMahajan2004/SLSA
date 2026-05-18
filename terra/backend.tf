#Here I have created th e backend configuration for terraform to store the state file in s3 bucket. This will help me to keep the track of the changes in the infrastructure and also it will help me to collaborate with other team members. I have also added the region where I want to store the state file. In this case, I have chosen ap-southeast-2 region.
terraform {
  backend "s3" {
    bucket = "terraformstate.01"
    key    = "secure-cicd/terraform.tfstate"
    region = "ap-southeast-2"
  }
}