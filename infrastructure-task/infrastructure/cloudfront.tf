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
    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
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
