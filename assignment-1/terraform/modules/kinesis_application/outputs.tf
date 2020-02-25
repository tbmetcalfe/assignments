output "bucket_name" {
  value = aws_s3_bucket.firehose_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.firehose_bucket.arn
}

output "kinesis_stream_arn" {
  value = aws_kinesis_firehose_delivery_stream.test_stream.arn
}

output "kinesis_stream_name" {
  value = "${var.stack_name}-kinesis-firehose-stream"
}
