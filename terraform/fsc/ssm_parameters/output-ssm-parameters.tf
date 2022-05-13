module "output_stringlist_parameters" {
  source = "../modules/output_stringlist_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/asg/instances/lifecycle-hook/launching/name"
      value       = local.asg_instances_lifecycle_hook_launching
      description = "Launching Lifecycle Hook Names"
    },

    {
      name        = "/central/asg/instances/lifecycle-hook/terminating/name"
      value       = local.asg_instances_lifecycle_hook_terminating
      description = "Terminating Lifecycle Hook Names"
    }
  ]
}

module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    # Launching Lifecycle Hooks
    {
      name        = "/central/asg/delta-delivery/lifecycle-hook/launching/name"
      value       = local.asg_delta_delivery_lifecycle_hook_launching
      description = "Delta Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/delta-xdelivery/lifecycle-hook/launching/name"
      value       = local.asg_delta_xdelivery_lifecycle_hook_launching
      description = "Delta Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/customer-delivery/lifecycle-hook/launching/name"
      value       = local.asg_customer_delivery_lifecycle_hook_launching
      description = "Customer Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/customer-xdelivery/lifecycle-hook/launching/name"
      value       = local.asg_customer_xdelivery_lifecycle_hook_launching
      description = "Customer Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf-inbound-delivery/lifecycle-hook/launching/name"
      value       = local.asg_mf_inbound_delivery_lifecycle_hook_launching
      description = "MF Inbound Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf-inbound-xdelivery/lifecycle-hook/launching/name"
      value       = local.asg_mf_inbound_xdelivery_lifecycle_hook_launching
      description = "MF Inbound Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf-outbound-delivery/lifecycle-hook/launching/name"
      value       = local.asg_mf_outbound_delivery_lifecycle_hook_launching
      description = "MF Outbound Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf-outbound-xdelivery/lifecycle-hook/launching/name"
      value       = local.asg_mf_outbound_xdelivery_lifecycle_hook_launching
      description = "MF Outbound Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/internet-delivery/lifecycle-hook/launching/name"
      value       = local.asg_internet_delivery_lifecycle_hook_launching
      description = "Internet Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/internet-xdelivery/lifecycle-hook/launching/name"
      value       = local.asg_internet_xdelivery_lifecycle_hook_launching
      description = "Internet Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/risky-delivery/lifecycle-hook/launching/name"
      value       = local.asg_risky_delivery_lifecycle_hook_launching
      description = "Risky Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/risky-xdelivery/lifecycle-hook/launching/name"
      value       = local.asg_risky_xdelivery_lifecycle_hook_launching
      description = "Risky Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/warmup-delivery/lifecycle-hook/launching/name"
      value       = local.asg_warmup_delivery_lifecycle_hook_launching
      description = "Warmup Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/warmup-xdelivery/lifecycle-hook/launching/name"
      value       = local.asg_warmup_xdelivery_lifecycle_hook_launching
      description = "Warmup Xdelivery Launching Lifecycle Hook Name"
    },
    # Terminating Lifecycle Hooks
    {
      name        = "/central/asg/delta-delivery/lifecycle-hook/terminating/name"
      value       = local.asg_delta_delivery_lifecycle_hook_terminating
      description = "Delta Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/encryption-delivery/lifecycle-hook/terminating/name"
      value       = local.asg_encryption_delivery_lifecycle_hook_terminating
      description = "Encryption Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/encryption-submit/lifecycle-hook/terminating/name"
      value       = local.asg_encryption_submit_lifecycle_hook_terminating
      description = "Encryption Submit Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/customer-delivery/lifecycle-hook/terminating/name"
      value       = local.asg_customer_delivery_lifecycle_hook_terminating
      description = "Customer Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/internet-submit/lifecycle-hook/terminating/name"
      value       = local.asg_internet_submit_lifecycle_hook_terminating
      description = "Internet Submit Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf-inbound-delivery/lifecycle-hook/terminating/name"
      value       = local.asg_mf_inbound_delivery_lifecycle_hook_terminating
      description = "MF Inbound Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf-inbound-submit/lifecycle-hook/terminating/name"
      value       = local.asg_mf_inbound_submit_lifecycle_hook_terminating
      description = "MF Inbound Submit Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf-outbound-delivery/lifecycle-hook/terminating/name"
      value       = local.asg_mf_outbound_delivery_lifecycle_hook_terminating
      description = "MF Outbound Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf-outbound-submit/lifecycle-hook/terminating/name"
      value       = local.asg_mf_outbound_submit_lifecycle_hook_terminating
      description = "MF Outbound Submit Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/internet-delivery/lifecycle-hook/terminating/name"
      value       = local.asg_internet_delivery_lifecycle_hook_terminating
      description = "Internet Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/customer-submit/lifecycle-hook/terminating/name"
      value       = local.asg_customer_submit_lifecycle_hook_terminating
      description = "Customer Submit Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/risky-delivery/lifecycle-hook/terminating/name"
      value       = local.asg_risky_delivery_lifecycle_hook_terminating
      description = "Risky Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/warmup-delivery/lifecycle-hook/terminating/name"
      value       = local.asg_warmup_delivery_lifecycle_hook_terminating
      description = "Warmup Delivery Terminating Lifecycle Hook Name"
    },
    {
      name        = "xgemail_white_space_remove_from_header_aws_regions"
      value       = local.xgemail_white_space_remove_from_header_aws_regions
      description = "Warmup Delivery Terminating Lifecycle Hook Name"
    },
    {
      name        = "xgemail_white_space_remove_from_header_client_ids"
      value       = local.xgemail_white_space_remove_from_header_client_ids
      description = "Warmup Delivery Terminating Lifecycle Hook Name"
    }
  ]
}
