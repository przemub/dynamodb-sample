resource "aws_lambda_function" "test_lambda" {
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_images.repository_url}:${data.aws_ecr_image.lambda_image.image_tag}"
  function_name = "lambda_test"
  role          = aws_iam_role.iam_for_lambda.arn
  image_config  {
    command = [ "endpoints.test.test_handler" ]
  }
}

resource "aws_lambda_permission" "test_allow_api" {
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

resource "aws_lambda_function" "get_candidate_lambda" {
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_images.repository_url}@${data.aws_ecr_image.lambda_image.image_digest}"
  function_name = "get_candidate"
  role          = aws_iam_role.iam_for_lambda.arn
  image_config  {
    command = [ "endpoints.candidate.get_candidate_handler" ]
  }
}

resource "aws_lambda_permission" "get_candidate_allow_api" {
  statement_id  = "AllowExecutionFromRESTAPI"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_candidate_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.dynamo-sample.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "candidate" {
  parent_id   = aws_api_gateway_rest_api.dynamo-sample.root_resource_id
  path_part   = "candidate"
  rest_api_id = aws_api_gateway_rest_api.dynamo-sample.id
  depends_on = [aws_api_gateway_rest_api.dynamo-sample]
}

resource "aws_api_gateway_method" "candidate_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.candidate.id
  rest_api_id   = aws_api_gateway_resource.candidate.rest_api_id
  depends_on    = [aws_api_gateway_resource.candidate]
}

resource "aws_api_gateway_integration" "candidate_get_integration" {
  rest_api_id             = aws_api_gateway_method.candidate_get.rest_api_id
  resource_id             = aws_api_gateway_method.candidate_get.resource_id
  http_method             = aws_api_gateway_method.candidate_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_candidate_lambda.invoke_arn
  depends_on = [aws_api_gateway_method.candidate_get, aws_lambda_function.get_candidate_lambda]
}

resource "aws_api_gateway_method" "candidate_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.candidate.id
  rest_api_id   = aws_api_gateway_resource.candidate.rest_api_id
  depends_on    = [aws_api_gateway_resource.candidate]
}

resource "aws_lambda_function" "post_candidate_lambda" {
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_images.repository_url}@${data.aws_ecr_image.lambda_image.image_digest}"
  function_name = "post_candidate"
  role          = aws_iam_role.iam_for_lambda.arn
  image_config  {
    command = [ "endpoints.candidate.post_candidate_handler" ]
  }
}

resource "aws_lambda_permission" "post_candidate_allow_api" {
  statement_id  = "AllowExecutionFromRESTAPI"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_candidate_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.dynamo-sample.execution_arn}/*/*"
}

resource "aws_api_gateway_integration" "candidate_post_integration" {
  rest_api_id             = aws_api_gateway_method.candidate_post.rest_api_id
  resource_id             = aws_api_gateway_method.candidate_post.resource_id
  http_method             = aws_api_gateway_method.candidate_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_candidate_lambda.invoke_arn
  depends_on = [aws_api_gateway_method.candidate_post, aws_lambda_function.post_candidate_lambda]
}

resource "aws_api_gateway_method" "candidate_delete" {
  authorization = "NONE"
  http_method   = "DELETE"
  resource_id   = aws_api_gateway_resource.candidate.id
  rest_api_id   = aws_api_gateway_resource.candidate.rest_api_id
  depends_on    = [aws_api_gateway_resource.candidate]
}

resource "aws_lambda_function" "delete_candidate_lambda" {
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_images.repository_url}@${data.aws_ecr_image.lambda_image.image_digest}"
  function_name = "delete_candidate"
  role          = aws_iam_role.iam_for_lambda.arn
  image_config  {
    command = [ "endpoints.candidate.delete_candidate_handler" ]
  }
}

resource "aws_lambda_permission" "delete_candidate_allow_api" {
  statement_id  = "AllowExecutionFromRESTAPI"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_candidate_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.dynamo-sample.execution_arn}/*/*"
}

resource "aws_api_gateway_integration" "candidate_delete_integration" {
  rest_api_id             = aws_api_gateway_method.candidate_delete.rest_api_id
  resource_id             = aws_api_gateway_method.candidate_delete.resource_id
  http_method             = aws_api_gateway_method.candidate_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.delete_candidate_lambda.invoke_arn
}
