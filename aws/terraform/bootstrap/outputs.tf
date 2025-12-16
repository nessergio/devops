# Output variable definitions
 
output "arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.config.arn
}
 
output "name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.config.id
}
 