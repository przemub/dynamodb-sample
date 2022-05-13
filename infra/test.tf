resource "aws_lambda_function" "test_lambda" {
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_images.repository_url}:${data.aws_ecr_image.lambda_image.image_tag}"
  function_name = "lambda_test"
  role          = aws_iam_role.iam_for_lambda.arn
  image_config  {
    command = [ "endpoints.test.test_handler" ]
  }
}

resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowExecutionFromRESTAPI"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.dynamo-sample.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "test" {
  parent_id   = aws_api_gateway_rest_api.dynamo-sample.root_resource_id
  path_part   = "test"
  rest_api_id = aws_api_gateway_rest_api.dynamo-sample.id
  depends_on = [aws_api_gateway_rest_api.dynamo-sample]
}

resource "aws_api_gateway_method" "test_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.test.id
  rest_api_id   = aws_api_gateway_resource.test.rest_api_id
  depends_on    = [aws_api_gateway_resource.test]
}

resource "aws_api_gateway_integration" "test_integration" {
  rest_api_id             = aws_api_gateway_method.test_get.rest_api_id
  resource_id             = aws_api_gateway_method.test_get.resource_id
  http_method             = aws_api_gateway_method.test_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
  depends_on = [aws_api_gateway_method.test_get, aws_lambda_function.test_lambda]
}
