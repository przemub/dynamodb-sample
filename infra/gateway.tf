resource "aws_api_gateway_account" "my_account" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_api_gateway_rest_api" "dynamo-sample" {
  name = "dynamo-sample"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.dynamo-sample.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.test_integration.id,
      aws_api_gateway_integration.candidate_get_integration.id,
      aws_api_gateway_integration.candidate_post_integration.id,
      aws_api_gateway_integration.candidate_delete_integration.id,
      data.aws_ecr_image.lambda_image.image_digest,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "test" {
  deployment_id = aws_api_gateway_deployment.deployment .id
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

resource "aws_api_gateway_api_key" "test" {
  name = "test"
}

resource "aws_api_gateway_usage_plan" "test" {
  name = "test"

  api_stages {
    api_id = aws_api_gateway_rest_api.dynamo-sample.id
    stage  = aws_api_gateway_stage.test.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "test" {
  key_id        = aws_api_gateway_api_key.test.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.test.id
}

