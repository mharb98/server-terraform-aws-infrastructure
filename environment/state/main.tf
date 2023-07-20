# KMS key to encrypt content of s3 state bucket
resource "aws_kms_key" "terraform-bucket-key" {
  description             = "This key is used to encrypt s3 bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "key-alias" {
  name          = "alias/terraform-state-key"
  target_key_id = aws_kms_key.terraform-bucket-key.key_id
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = "marwan-s3-terraform-state-backend"
}

# resource for s3 backend encrypyion rule
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.terraform-state.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform-bucket-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 access block for setting the s3 bucket as private
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.terraform-state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform-state" {
  name           = "terraform-state"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
