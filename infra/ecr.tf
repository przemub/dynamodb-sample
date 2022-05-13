resource "aws_ecr_repository" "lambda_images" {
  name = "dynamo-sample"
}

data "aws_ecr_image" "lambda_image" {
  repository_name = aws_ecr_repository.lambda_images.name
  image_tag       = "latest"
  depends_on = [aws_ecr_repository.lambda_images]
}
