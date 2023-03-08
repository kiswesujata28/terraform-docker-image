output "arn" {
  value       = join("", aws_iam_user.test_user.*.arn)
  description = "The ARN assigned by AWS for this user."
}