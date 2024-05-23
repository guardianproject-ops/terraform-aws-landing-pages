module "cdn" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.94.0"
  context = module.this.context

  encryption_enabled = true

  # Allow for upgrading pre-existing instances - it's not possible to disable once enabled
  bucket_versioning = var.bucket_versioning

  # Caching Settings
  default_ttl                 = 0
  compress                    = true
  lambda_function_association = module.lambda_at_edge.lambda_function_association
  dns_alias_enabled           = true
  parent_zone_id              = data.aws_route53_zone.this.id
  aliases                     = [var.domain_name]
  acm_certificate_arn         = module.acm_request_certificate.arn
  depends_on                  = [module.acm_request_certificate]
}

data "aws_route53_zone" "this" {
  name = var.parent_zone_name
}

module "acm_request_certificate" {
  source  = "cloudposse/acm-request-certificate/aws"
  version = "0.17.0"

  domain_name                       = var.domain_name
  zone_id                           = data.aws_route53_zone.this.id
  process_domain_validation_options = true
  ttl                               = "300"
}

module "lambda_at_edge" {
  source  = "cloudposse/cloudfront-s3-cdn/aws//modules/lambda@edge"
  version = "0.94.0"

  context = module.this.context

  functions = {
    origin_request = {
      source = [{
        filename = "lambda_function.py"
        content  = templatefile("${path.module}/lambda.py.tftpl", { choices = var.choices })
      }]
      handler      = "lambda_function.lambda_handler"
      runtime      = "python3.10"
      event_type   = "origin-request"
      include_body = false
    }
  }
}

data "aws_iam_policy_document" "s3_read_write" {
  statement {
    sid = "AllowListBucket"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${module.cdn.s3_bucket}"
    ]
  }

  statement {
    sid = "AllowGetObject"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${module.cdn.s3_bucket}/*"
    ]
  }

  statement {
    sid = "AllowPutObject"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${module.cdn.s3_bucket}/*"
    ]
  }

  statement {
    sid = "AllowDeleteObject"
    actions = [
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${module.cdn.s3_bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_read_write" {
  name        = "S3_read_write"
  description = "Read/write access to landing pages S3 origin bucket"
  path        = "/"

  policy = data.aws_iam_policy_document.s3_read_write.json
}

module "deploy_user" {
  source     = "cloudposse/iam-system-user/aws"
  version    = "1.2.0"
  context    = module.this.context
  attributes = ["deploy"]

  create_iam_access_key = "true"
  ssm_enabled           = false
}

resource "aws_iam_user_policy_attachment" "s3_read_write" {
  user       = module.deploy_user.user_name
  policy_arn = aws_iam_policy.s3_read_write.arn
}
