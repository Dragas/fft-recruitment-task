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

// The role that will be used to run our lambda function
resource "aws_iam_role" "lambda_role" {
  name               = "lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_edge_runner.json
}

resource "aws_iam_policy" "lambda_log_policy" {
  name   = "lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_log.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_log_policy.arn
}


resource "aws_iam_role_policy_attachment" "response_lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_log_policy.arn
}