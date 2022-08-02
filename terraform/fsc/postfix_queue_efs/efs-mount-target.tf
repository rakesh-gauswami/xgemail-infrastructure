resource "aws_efs_mount_target" "mount-target-subnet-a" {
  file_system_id  = aws_efs_file_system.xgemail-postfix-queue-efs-volume.id
  subnet_id       = element(local.input_param_subnet_ids, 0)
  security_groups = [local.input_param_security_groups]
}

resource "aws_efs_mount_target" "mount-target-subnet-b" {
  file_system_id  = aws_efs_file_system.xgemail-postfix-queue-efs-volume.id
  subnet_id       = element(local.input_param_subnet_ids, 1)
  security_groups = [local.input_param_security_groups]
}

resource "aws_efs_mount_target" "mount-target-subnet-c" {
  file_system_id  = aws_efs_file_system.xgemail-postfix-queue-efs-volume.id
  subnet_id       = element(local.input_param_subnet_ids, 2)
  security_groups = [local.input_param_security_groups]
}