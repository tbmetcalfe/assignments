resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "${var.stack_name}-firehose-bucket"
  acl    = "private"
}

resource "aws_iam_role" "firehose_role" {
  name = "${var.stack_name}-firehose_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "${var.stack_name}-kinesis-firehose-stream"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.firehose_bucket.arn
    prefix     = "${var.stack_name}-data"
  }
}
