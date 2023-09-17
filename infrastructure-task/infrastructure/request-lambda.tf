// Zip up the lambda function source code
data "archive_file" "request_lambda" {
  type             = "zip"
  output_file_mode = "0444"
  source_file      = "viewer-request-lambda/index.js"
  output_path      = "viewer-request-lambda/deploy.zip"
}

// Create the lambda function using the code in the zip-file
resource "aws_lambda_function" "viewer_request_lambda" {
  filename         = data.archive_file.request_lambda.output_path
  function_name    = "viewer-request"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.request_lambda.output_base64sha256
  runtime          = "nodejs18.x"
  publish          = true
#  lambda at edge cannot have envs
#  environment {
#    variables = local.common_lambda_envs
#  }
}




