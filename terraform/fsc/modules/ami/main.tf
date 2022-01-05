locals {
  ami_owner_account = 843638552935
  ami_fallback_branch = "develop"
  ami_data = regex("^hmr-core-(?P<branch>[\\S+]+)-(?P<type>[xgemail]+)-(?P<build>[\\d+]+)-(?P<uuid>[\\d+]+)", data.aws_ami.ami.name)

}

data "aws_ami" "ami" {
  provider         = aws

  most_recent      = true
  owners           = [local.ami_owner_account]

  filter {
    name   = "name"
    values = ["hmr-core-${try(var.build_branch, local.ami_fallback_branch)}-xgemail-*"]
  }

  filter {
    name   = "is-public"
    values = ["false"]
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
