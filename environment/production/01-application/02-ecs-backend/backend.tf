terraform {
  backend "s3" {
    bucket         = "marwan-s3-terraform-state-backend"
    key            = "production/01-application/02-ecs-backend/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    kms_key_id     = "39405ab6-d9af-449b-a65b-33c1afed10c6"
    dynamodb_table = "terraform-state"
  }
}
