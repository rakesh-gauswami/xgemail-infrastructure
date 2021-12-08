module "output_stringlist_parameters" {
  source = "../modules/output_stringlist_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/asg/instances/lifecycle_hook/launching/name"
      value       = local.asg_instances_lifecycle_hook_launching
      description = "Launching Lifecycle Hook Names"
    },

    {
      name        = "/central/asg/instances/lifecycle_hook/terminating/name"
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

    {
      name        = "/central/asg/delta_delivery/lifecycle_hook/launching/name"
      value       = local.asg_delta_delivery_lifecycle_hook_launching
      description = "Delta Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/delta_xdelivery/lifecycle_hook/launching/name"
      value       = local.asg_delta_xdelivery_lifecycle_hook_launching
      description = "Delta Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/inbound_delivery/lifecycle_hook/launching/name"
      value       = local.asg_inbound_delivery_lifecycle_hook_launching
      description = "Inbound Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf_inbound_delivery/lifecycle_hook/launching/name"
      value       = local.asg_mf_inbound_delivery_lifecycle_hook_launching
      description = "MF Inbound Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf_inbound_xdelivery/lifecycle_hook/launching/name"
      value       = local.asg_mf_inbound_xdelivery_lifecycle_hook_launching
      description = "MF Inbound Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf_outbound_delivery/lifecycle_hook/launching/name"
      value       = local.asg_mf_outbound_delivery_lifecycle_hook_launching
      description = "MF Outbound Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf_outbound_xdelivery/lifecycle_hook/launching/name"
      value       = local.asg_mf_outbound_xdelivery_lifecycle_hook_launching
      description = "MF Outbound Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/outbound_delivery/lifecycle_hook/launching/name"
      value       = local.asg_outbound_delivery_lifecycle_hook_launching
      description = "Outbound Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/outbound_xdelivery/lifecycle_hook/launching/name"
      value       = local.asg_outbound_xdelivery_lifecycle_hook_launching
      description = "Outbound Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/risky_delivery/lifecycle_hook/launching/name"
      value       = local.asg_risky_delivery_lifecycle_hook_launching
      description = "Risky Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/risky_xdelivery/lifecycle_hook/launching/name"
      value       = local.asg_risky_xdelivery_lifecycle_hook_launching
      description = "Risky Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/warmup_delivery/lifecycle_hook/launching/name"
      value       = local.asg_warmup_delivery_lifecycle_hook_launching
      description = "Warmup Delivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/warmup_xdelivery/lifecycle_hook/launching/name"
      value       = local.asg_warmup_xdelivery_lifecycle_hook_launching
      description = "Warmup Xdelivery Launching Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/delta_delivery/lifecycle_hook/terminating/name"
      value       = local.asg_delta_delivery_lifecycle_hook_terminating
      description = "Delta Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/inbound_delivery/lifecycle_hook/terminating/name"
      value       = local.asg_inbound_delivery_lifecycle_hook_terminating
      description = "Inbound Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf_inbound_delivery/lifecycle_hook/terminating/name"
      value       = local.asg_mf_inbound_delivery_lifecycle_hook_terminating
      description = "MF Inbound Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/mf_outbound_delivery/lifecycle_hook/terminating/name"
      value       = local.asg_mf_outbound_delivery_lifecycle_hook_terminating
      description = "MF Outbound Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/outbound_delivery/lifecycle_hook/terminating/name"
      value       = local.asg_outbound_delivery_lifecycle_hook_terminating
      description = "Outbound Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/risky_delivery/lifecycle_hook/terminating/name"
      value       = local.asg_risky_delivery_lifecycle_hook_terminating
      description = "Risky Delivery Terminating Lifecycle Hook Name"
    },

    {
      name        = "/central/asg/warmup_delivery/lifecycle_hook/terminating/name"
      value       = local.asg_warmup_delivery_lifecycle_hook_terminating
      description = "Warmup Delivery Terminating Lifecycle Hook Name"
    }
  ]
}
