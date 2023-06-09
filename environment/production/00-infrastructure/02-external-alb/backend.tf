terraform {
  backend "s3" {
    bucket         = "marwan-s3-terraform-state-backend"
    key            = "production/00-infrastructure/02-external-alb/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    kms_key_id     = "75eeba81-1e8f-45f4-94ef-4eb3c77c8faf"
    dynamodb_table = "terraform-state"
  }
}
