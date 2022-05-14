resource "aws_ecr_repository" "lambda_images" {
  name = "dynamo-sample"
}

data "aws_ecr_image" "lambda_image" {
  repository_name = aws_ecr_repository.lambda_images.name
  image_tag       = "latest"
  depends_on = [aws_ecr_repository.lambda_images]
}

resource "aws_ecr_repository" "foo" {
  name = "bar"
}

resource "aws_ecr_lifecycle_policy" "lambda_policy" {
  repository = aws_ecr_repository.lambda_images.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images older than 1 day",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
