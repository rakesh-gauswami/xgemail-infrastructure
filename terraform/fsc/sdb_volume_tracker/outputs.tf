##################################################################################
# OUTPUT
##################################################################################

output "volume_tracker_name" {
  value = aws_simpledb_domain.volume_tracker.name
}

output "volume_tracker_id" {
  value = aws_simpledb_domain.volume_tracker.id
}

output "volume_tracker_simpledb_policy_arn" {
  value = aws_iam_policy.volume_tracker_simpledb_policy.arn
}

output "volume_tracker_simpledb_policy_name" {
  value = aws_iam_policy.volume_tracker_simpledb_policy.name
}
