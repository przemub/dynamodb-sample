data "archive_file" "lambda-source" {
  type = "zip"

  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/lambda-source.zip"
}

