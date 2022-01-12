locals {
  ami_owner_account = 843638552935
  ami_data          = regex("^hmr-core-(?P<branch>[\\S+]+)-(?P<type>[xgemail]+)-(?P<build>[\\d+]+)-(?P<uuid>[\\d+]+)", data.aws_ami.ami.name)
  ami_build         = local.ami_data.build
}

data "aws_ami" "ami" {
  most_recent = true
  owners      = [local.ami_owner_account]

  filter {
    name   = "name"
# using develop for testing since ami build of feature branch failing
#    values = ["hmr-core-${var.build_branch}-xgemail-*"]
     values = ["hmr-core-develop-xgemail-*"]
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
