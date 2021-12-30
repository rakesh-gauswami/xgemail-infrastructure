module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [

    {
      name        = "/central/iam/roles/autoscaling/arn"
      value       = aws_iam_role.autoscaling_role.arn
      description = "IAM Role ARN for Autoscaling Service Role"
    },

    {
      name        = "/central/iam/profiles/encryption-delivery-instance/arn"
      value       = aws_iam_instance_profile.encryption_delivery_instance_profile.arn
      description = "IAM Instance Profile ARN for Encryption Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/encryption-submit-instance/arn"
      value       = aws_iam_instance_profile.encryption_submit_instance_profile.name
      description = "IAM Instance Profile ARN for Encryption Submit Instance"
    },

    {
      name        = "/central/iam/profiles/customer-delivery-instance/arn"
      value       = aws_iam_instance_profile.customer_delivery_instance_profile.name
      description = "IAM Instance Profile ARN for Customer Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/customer-xdelivery-instance/arn"
      value       = aws_iam_instance_profile.customer_xdelivery_instance_profile.name
      description = "IAM Instance Profile ARN for Customer Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/customer-submit-instance/arn"
      value       = aws_iam_instance_profile.customer_submit_instance_profile.name
      description = "IAM Instance Profile ARN for Customer Submit Instance"
    },

    {
      name        = "/central/iam/profiles/internet-delivery-instance/arn"
      value       = aws_iam_instance_profile.internet_delivery_instance_profile.name
      description = "IAM Instance Profile ARN for Internet Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/internet-xdelivery-instance/arn"
      value       = aws_iam_instance_profile.internet_xdelivery_instance_profile.name
      description = "IAM Instance Profile ARN for Internet Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/internet-submit-instance/arn"
      value       = aws_iam_instance_profile.internet_submit_instance_profile.arn
      description = "IAM Instance Profile ARN for Internet Submit Instance"
    },

    {
      name        = "/central/iam/profiles/delta-delivery-instance/arn"
      value       = aws_iam_instance_profile.delta_delivery_instance_profile.name
      description = "IAM Instance Profile ARN for Delta Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/delta-xdelivery-instance/arn"
      value       = aws_iam_instance_profile.delta_xdelivery_instance_profile.name
      description = "IAM Instance Profile ARN for Delta Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/risky-delivery-instance/arn"
      value       = aws_iam_instance_profile.risky_delivery_instance_profile.name
      description = "IAM Instance Profile ARN for Risky Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/risky-xdelivery-instance/arn"
      value       = aws_iam_instance_profile.risky_xdelivery_instance_profile.name
      description = "IAM Instance Profile ARN for Risky Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/warmup-delivery-instance/arn"
      value       = aws_iam_instance_profile.warmup_delivery_instance_profile.name
      description = "IAM Instance Profile ARN for Warmup Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/warmup-xdelivery-instance/arn"
      value       = aws_iam_instance_profile.warmup_xdelivery_instance_profile.name
      description = "IAM Instance Profile ARN for Warmup Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-inbound-delivery-instance/arn"
      value       = aws_iam_instance_profile.mf_inbound_delivery_instance_profile.name
      description = "IAM Instance Profile ARN for MF Inbound Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-inbound-xdelivery-instance/arn"
      value       = aws_iam_instance_profile.mf_inbound_xdelivery_instance_profile.name
      description = "IAM Instance Profile ARN for MF Inbound Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-outbound-submit-instance/arn"
      value       = aws_iam_instance_profile.mf_outbound_submit_instance_profile.name
      description = "IAM Instance Profile ARN for MF Outbound Submit Instance"
    },

    {
      name        = "/central/iam/profiles/mf-outbound-delivery-instance/arn"
      value       = aws_iam_instance_profile.mf_outbound_delivery_instance_profile.name
      description = "IAM Instance Profile ARN for MF Outbound Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-outbound-xdelivery-instance/arn"
      value       = aws_iam_instance_profile.mf_outbound_xdelivery_instance_profile.name
      description = "IAM Instance Profile ARN for MF Outbound Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-inbound-submit-instance/arn"
      value       = aws_iam_instance_profile.mf_inbound_submit_instance_profile.arn
      description = "IAM Instance Profile ARN for MF Inbound Submit Instance"
    }

  ]
}
