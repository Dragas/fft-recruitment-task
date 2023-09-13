// Allows AWS the use the role on our behalf
// - in the test UI (lambda.amazonaws.com)
// - as a Lambda@Edge function in CloudFront (edgelambda.amazonaws.com)
data "aws_iam_policy_document" "lambda_edge_runner" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

// Allows the role to create and write to logs
data "aws_iam_policy_document" "lambda_log" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}