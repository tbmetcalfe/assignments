provider "aws" {

  region = var.region

  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    firehose = "http://localhost:4573"
    iam      = "http://localhost:4593"
    kinesis  = "http://localhost:4568"
    s3       = "http://localhost:4572"
  }
}
