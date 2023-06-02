terraform {
  backend "s3" {
    bucket         = "marwan-harb-s3-terraform-state-backend"
    key            = "production/01-application/01-cloudfront/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    kms_key_id     = "75eeba81-1e8f-45f4-94ef-4eb3c77c8faf"
    dynamodb_table = "terraform-state"
  }
}
