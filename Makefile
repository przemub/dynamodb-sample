SHELL := /bin/bash

build:
	docker build -t dynamo-sample .

run: build
	docker run --rm -p 9000:8080 dynamo-sample:latest

ECR_URL = $(shell cd infra && terraform show -json | jq -r '.values.root_module.resources[] | select(.address == "aws_ecr_repository.lambda_images") | .values.repository_url')
push: build
	cd infra && terraform apply -target aws_ecr_repository.lambda_images
	aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${ECR_URL}
	docker tag dynamo-sample:latest "${ECR_URL}"
	docker push "${ECR_URL}:latest"

INVOKE_URL = $(shell cd infra && terraform show -json | jq -r '.values.root_module.resources[] | select(.address == "aws_api_gateway_stage.test") | .values.invoke_url')
deploy: push
	cd infra && terraform apply
	@echo "Deployed successfully under ${INVOKE_URL}!"
