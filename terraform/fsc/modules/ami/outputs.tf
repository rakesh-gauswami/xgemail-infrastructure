output "id" {
  value = data.aws_ami.ami.id
}

output "name" {
  value = data.aws_ami.ami.name
}

output "description" {
  value = data.aws_ami.ami.description
}

output "tags" {
  value = data.aws_ami.ami.tags
}

output "data" {
  value = local.ami_data
}

output "build" {
  value = local.ami_data.build
}
