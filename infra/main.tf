data "archive_file" "lambda-source" {
  type = "zip"

  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/lambda-source.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role = aws_iam_role.cloudwatch.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "my_account" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_api_gateway_rest_api" "dynamo-sample" {
  name = "dynamo-sample"
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.dynamo-sample.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.dynamo-sample.id))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "test" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.dynamo-sample.id
  stage_name    = "test"
  depends_on = [aws_cloudwatch_log_group.execution_logs]
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.execution_logs.arn
    format          = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
}

resource "aws_cloudwatch_log_group" "execution_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.dynamo-sample.id}/test"
  retention_in_days = 7
}
