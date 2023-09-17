// The CloudFront distribution which serves our little site
// It relies on a lambda function for "pretty" routing without .html extensions in the URL
resource "aws_cloudfront_distribution" "cloudfront" {
  comment             = "For FFT assignment"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  enabled             = true

  // The S3 bucket to fetch files from
  origin {
    origin_id                = "files"
    domain_name              = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cf_to_s3.id
    origin_path = "/app"
  }

  // For any request, use the files from the S3 bucket
  default_cache_behavior {
    target_origin_id       = "files"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    # cache_policy_id = aws_cloudfront_cache_policy.experiment_cookie_policy
    cache_policy_id        = "943583f4-f58e-4f72-b1bb-c34f17598b43"
  }

  ordered_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    path_pattern           = "/home*"
    target_origin_id       = "files"
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        whitelisted_names = [
          "Experiment"
        ]
        forward = "whitelist"
      }
    }
    // Invoke the lambda function as the first part of processing every request
    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.viewer_request_lambda.qualified_arn
    }
    lambda_function_association {
      event_type = "viewer-response"
      lambda_arn = aws_lambda_function.viewer_response_lambda.qualified_arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

// Allows the S3 bucket to identify when our CloudFront distribution is trying to read from it
resource "aws_cloudfront_origin_access_control" "cf_to_s3" {
  name                              = "cf-to-s3"
  description                       = "Allow CloudFront access to S3 files"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

// include AB testing cookie in the cache key
// might be this issue: https://github.com/hashicorp/terraform-provider-aws/issues/22467#issuecomment-1684322257
// crashed on windows terraform-aws-provider 5.14.0
// create by hand and import uuid
#resource "aws_cloudfront_cache_policy" "experiment_cookie_policy" {
#  name = "experiment_cookie_policy"
#  comment = "includes experiment cookie in the cache key"
#  default_ttl = 3600
#  max_ttl = 86400
#  min_ttl = 600
#  parameters_in_cache_key_and_forwarded_to_origin {
#    enable_accept_encoding_gzip = true
#    enable_accept_encoding_brotli = true
#    cookies_config {
#      cookie_behavior = "whitelist"
#      cookies {
#        // should come from some constants file and get written to both request and response lambdas
#        items = ["Experiment"]
#      }
#    }
#    headers_config {}
#    query_strings_config {
#      query_string_behavior = "none"
#    }
#  }
#}
# ignored by windows terraform
#import {
#  to = aws_cloudfront_cache_policy.experiment_cookie_policy
#  id = "943583f4-f58e-4f72-b1bb-c34f17598b43"
#}

