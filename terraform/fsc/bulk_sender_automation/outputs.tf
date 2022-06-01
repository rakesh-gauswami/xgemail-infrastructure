output "bulk_sender_automation_name" {
  value = aws_ssm_document.bulk_sender_automation.name
}

output "bulk_sender_automation_role_arn" {
  value = aws_iam_role.bulk_sender_automation_role.arn
}

output "bulk_sender_automation_role_name" {
  value = aws_iam_role.bulk_sender_automation_role.id
}
