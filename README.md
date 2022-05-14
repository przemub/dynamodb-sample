## DynamoDB sample project

A very simple serverless API Gateway + Lambda + DynamoDB project, storing
exam candidates behind a REST API. The project is deployed using Terraform.

![Project structure](https://github.com/przemub/dynamodb-sample/raw/master/diagram.png "Project structure")

### Deployment

* Set up AWS credentials in your environment
* Run `make deploy`
* Enter `yes` when asked by Terraform (twice!)
* With some luck and prayer, you should get the endpoint URL as the last message!
