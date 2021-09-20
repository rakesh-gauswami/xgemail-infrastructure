resource "aws_kms_key" "key" {
  description = var.description
  enable_key_rotation = true
  tags = {
    Name = var.alias
  }
}

resource "aws_kms_alias" "alias" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.key.key_id
}
