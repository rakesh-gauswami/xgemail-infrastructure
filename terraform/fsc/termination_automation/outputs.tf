output "termination_automation_event_rule_role_arn" {
  value = aws_iam_role.termination_automation_event_rule_role.arn
}

output "termination_automation_event_rule_role_name" {
  value = aws_iam_role.termination_automation_event_rule_role.name
}

output "termination_automation_event_rule_arn" {
  value = aws_cloudwatch_event_rule.termination_automation.arn
}

output "termination_automation_event_rule_name" {
  value = aws_cloudwatch_event_rule.termination_automation.name
}

output "termination_automation_role_arn" {
  value = aws_iam_role.termination_automation_role.arn
}

output "termination_automation_role_name" {
  value = aws_iam_role.termination_automation_role.name
}

output "termination_automation_ssm_document_name" {
  value = aws_ssm_document.termination_automation.name
}
