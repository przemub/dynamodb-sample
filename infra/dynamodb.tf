resource "aws_dynamodb_table" "candidates" {
  hash_key = "name"
  billing_mode = "PAY_PER_REQUEST"
  name     = "candidates"

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }

  global_secondary_index {
    hash_key        = "id"
    name            = "by_id"
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_table" "counters" {
  hash_key = "counterName"
  billing_mode = "PAY_PER_REQUEST"
  name     = "counters"
  attribute {
    name = "counterName"
    type = "S"
  }
}
