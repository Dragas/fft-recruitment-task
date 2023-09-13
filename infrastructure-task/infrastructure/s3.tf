// Use the account name in the S3 bucket name, because buckets must be globally unique
data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "site_bucket" {
  bucket = "fft-assignment-files-${data.aws_caller_identity.current.account_id}"
}

// A policy that allows our CloudFront distribution to read files from this bucket
data "aws_iam_policy_document" "site_bucket_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = ["${aws_s3_bucket.site_bucket.arn}/*", aws_s3_bucket.site_bucket.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cloudfront.arn]
    }
  }
}

// Apply the policy above to the bucket
resource "aws_s3_bucket_policy" "site_bucket_policy" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.site_bucket_policy.json
}

locals {
  application_directory = "../../NextApp"
  // some file endings have multiple mimetypes
  // so when using just pick first available
  // doesnt matter for exercise
  // csv files are shamelessly taken from https://www.iana.org/assignments/media-types/media-types.xhtml
  // slightly modified to include js files
  mimetypes = {for idx, it in flatten([for it in fileset("mime", "*") : csvdecode(file("mime/${it}"))]) : ".${it.Name}" => it.Template...}
}

resource "aws_s3_object" "app" {
  for_each = fileset(local.application_directory, "**")
  bucket = aws_s3_bucket.site_bucket.id
  key = each.value
  source = "${local.application_directory}/${each.value}"
  etag = filemd5("${local.application_directory}/${each.value}")
  // aws_s3_object does not figure out the mimetype of the file being uploaded, so
  // it must be generated on the go by fetching anything that comes after .
  // and inferring that from the mimetype map as key
  // in case it cannot be done, set binary/octet-stream (the default)
  // refer to local.mimetypes map
  content_type = lookup(local.mimetypes, regex("\\.[^.]+$", each.value), "binary/octet-stream")[0]
}
