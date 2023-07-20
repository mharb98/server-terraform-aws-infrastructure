locals {
  environment = "production"
  app_name    = "demo"
}

data "terraform_remote_state" "external-alb" {
  backend = "s3"
  config = {
    bucket = "marwan-s3-terraform-state-backend"
    key    = "production/00-infrastructure/02-external-alb/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_cloudfront_cache_policy" "alb-cache-policy" {
  name        = "${local.environment}-alb-cache-policy"
  default_ttl = 50
  max_ttl     = 100
  min_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "all"
    }

  }
}

resource "aws_cloudfront_distribution" "demo-backend-distribution" {
  enabled = true
  # aliases = [var.domain_name]
  origin {
    domain_name = data.terraform_remote_state.external-alb.outputs.alb-dns-name
    origin_id   = data.terraform_remote_state.external-alb.outputs.alb-id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = data.terraform_remote_state.external-alb.outputs.alb-id
    viewer_protocol_policy = "allow-all"
    cache_policy_id        = aws_cloudfront_cache_policy.alb-cache-policy.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true

    # acm_certificate_arn      = aws_acm_certificate.cert.arn
    # ssl_support_method       = "sni-only"
    # minimum_protocol_version = "TLSv1.2_2018"
  }
}
