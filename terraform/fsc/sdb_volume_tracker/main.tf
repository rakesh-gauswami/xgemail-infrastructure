#
# SimpleDB Domain Template for Sophos MSG FSC VPC
#
resource "aws_simpledb_domain" "volume_tracker" {
  name = "volume_tracker"

  provider = aws.parameters
}
