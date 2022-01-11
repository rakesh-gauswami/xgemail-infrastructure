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
      name        = "/central/iam/profiles/encryption-delivery-instance/name"
      value       = aws_iam_instance_profile.encryption_delivery_instance_profile.name
      description = "IAM Instance Profile Name for Encryption Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/encryption-submit-instance/name"
      value       = aws_iam_instance_profile.encryption_submit_instance_profile.name
      description = "IAM Instance Profile Name for Encryption Submit Instance"
    },

    {
      name        = "/central/iam/profiles/customer-delivery-instance/name"
      value       = aws_iam_instance_profile.customer_delivery_instance_profile.name
      description = "IAM Instance Profile Name for Customer Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/customer-xdelivery-instance/name"
      value       = aws_iam_instance_profile.customer_xdelivery_instance_profile.name
      description = "IAM Instance Profile Name for Customer Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/customer-submit-instance/name"
      value       = aws_iam_instance_profile.customer_submit_instance_profile.name
      description = "IAM Instance Profile Name for Customer Submit Instance"
    },

    {
      name        = "/central/iam/profiles/internet-delivery-instance/name"
      value       = aws_iam_instance_profile.internet_delivery_instance_profile.name
      description = "IAM Instance Profile Name for Internet Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/internet-xdelivery-instance/name"
      value       = aws_iam_instance_profile.internet_xdelivery_instance_profile.name
      description = "IAM Instance Profile Name for Internet Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/internet-submit-instance/name"
      value       = aws_iam_instance_profile.internet_submit_instance_profile.name
      description = "IAM Instance Profile Name for Internet Submit Instance"
    },

    {
      name        = "/central/iam/profiles/delta-delivery-instance/name"
      value       = aws_iam_instance_profile.delta_delivery_instance_profile.name
      description = "IAM Instance Profile Name for Delta Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/delta-xdelivery-instance/name"
      value       = aws_iam_instance_profile.delta_xdelivery_instance_profile.name
      description = "IAM Instance Profile Name for Delta Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/risky-delivery-instance/name"
      value       = aws_iam_instance_profile.risky_delivery_instance_profile.name
      description = "IAM Instance Profile Name for Risky Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/risky-xdelivery-instance/name"
      value       = aws_iam_instance_profile.risky_xdelivery_instance_profile.name
      description = "IAM Instance Profile Name for Risky Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/warmup-delivery-instance/name"
      value       = aws_iam_instance_profile.warmup_delivery_instance_profile.name
      description = "IAM Instance Profile Name for Warmup Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/warmup-xdelivery-instance/name"
      value       = aws_iam_instance_profile.warmup_xdelivery_instance_profile.name
      description = "IAM Instance Profile Name for Warmup Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-inbound-delivery-instance/name"
      value       = aws_iam_instance_profile.mf_inbound_delivery_instance_profile.name
      description = "IAM Instance Profile Name for MF Inbound Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-inbound-xdelivery-instance/name"
      value       = aws_iam_instance_profile.mf_inbound_xdelivery_instance_profile.name
      description = "IAM Instance Profile Name for MF Inbound Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-outbound-submit-instance/name"
      value       = aws_iam_instance_profile.mf_outbound_submit_instance_profile.name
      description = "IAM Instance Profile Name for MF Outbound Submit Instance"
    },

    {
      name        = "/central/iam/profiles/mf-outbound-delivery-instance/name"
      value       = aws_iam_instance_profile.mf_outbound_delivery_instance_profile.name
      description = "IAM Instance Profile Name for MF Outbound Delivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-outbound-xdelivery-instance/name"
      value       = aws_iam_instance_profile.mf_outbound_xdelivery_instance_profile.name
      description = "IAM Instance Profile Name for MF Outbound Xdelivery Instance"
    },

    {
      name        = "/central/iam/profiles/mf-inbound-submit-instance/name"
      value       = aws_iam_instance_profile.mf_inbound_submit_instance_profile.name
      description = "IAM Instance Profile Name for MF Inbound Submit Instance"
    }

  ]
}
