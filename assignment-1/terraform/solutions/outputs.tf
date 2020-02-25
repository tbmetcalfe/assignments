output "kinesis_stream_arn" {
  value = module.kinesis_application.kinesis_stream_arn
}

output "kinesis_stream_name" {
  value = module.kinesis_application.kinesis_stream_name
}

output "bucket_name" {
  value = module.kinesis_application.bucket_name
}
