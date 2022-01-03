data "aws_ami" "ami" {
  most_recent      = true
  owners           = [local.ami_owner_account]

  filter {
    name   = "name"
    values = ["hmr-core-${local.build_branch}-xgemail-*"]
  }

  filter {
    name   = "is-public"
    values = ["no"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }
}