locals {
  # Launching Lifecycle Hooks
  asg_delta_delivery_lifecycle_hook_launching         = "delta-delivery-launching"
  asg_delta_xdelivery_lifecycle_hook_launching        = "delta-xdelivery-launching"
  asg_customer_delivery_lifecycle_hook_launching      = "customer-delivery-launching"
  asg_customer_xdelivery_lifecycle_hook_launching     = "customer-xdelivery-launching"
  asg_mf_inbound_delivery_lifecycle_hook_launching    = "mf-inbound-delivery-launching"
  asg_mf_inbound_xdelivery_lifecycle_hook_launching   = "mf-inbound-xdelivery-launching"
  asg_mf_outbound_delivery_lifecycle_hook_launching   = "mf-outbound-delivery-launching"
  asg_mf_outbound_xdelivery_lifecycle_hook_launching  = "mf-outbound-xdelivery-launching"
  asg_internet_delivery_lifecycle_hook_launching      = "internet-delivery-launching"
  asg_internet_xdelivery_lifecycle_hook_launching     = "internet-xdelivery-launching"
  asg_risky_delivery_lifecycle_hook_launching         = "risky-delivery-launching"
  asg_risky_xdelivery_lifecycle_hook_launching        = "risky-xdelivery-launching"
  asg_warmup_delivery_lifecycle_hook_launching        = "warmup-delivery-launching"
  asg_warmup_xdelivery_lifecycle_hook_launching       = "warmup-xdelivery-launching"
  # Terminating Lifecycle Hooks
  asg_delta_delivery_lifecycle_hook_terminating       = "delta-delivery-terminating"
  asg_encryption_submit_lifecycle_hook_terminating    = "encryption-submit-terminating"
  asg_encryption_delivery_lifecycle_hook_terminating  = "encryption-delivery-terminating"
  asg_customer_delivery_lifecycle_hook_terminating    = "customer-delivery-terminating"
  asg_internet_submit_lifecycle_hook_terminating      = "internet-submit-terminating"
  asg_mf_inbound_delivery_lifecycle_hook_terminating  = "mf-inbound-delivery-terminating"
  asg_mf_inbound_submit_lifecycle_hook_terminating    = "mf-inbound-submit-terminating"
  asg_mf_outbound_delivery_lifecycle_hook_terminating = "mf-outbound-delivery-terminating"
  asg_mf_outbound_submit_lifecycle_hook_terminating   = "mf-outbound-submit-terminating"
  asg_internet_delivery_lifecycle_hook_terminating    = "internet-delivery-terminating"
  asg_customer_submit_lifecycle_hook_terminating      = "customer-submit-terminating"
  asg_risky_delivery_lifecycle_hook_terminating       = "risky-delivery-terminating"
  asg_warmup_delivery_lifecycle_hook_terminating      = "warmup-delivery-terminating"

  newrelic_account_id                                 = "3452541"

  asg_instances_lifecycle_hook_launching = [
    local.asg_delta_delivery_lifecycle_hook_launching,
    local.asg_delta_xdelivery_lifecycle_hook_launching,
    local.asg_customer_delivery_lifecycle_hook_launching,
    local.asg_mf_inbound_delivery_lifecycle_hook_launching,
    local.asg_mf_inbound_xdelivery_lifecycle_hook_launching,
    local.asg_mf_outbound_delivery_lifecycle_hook_launching,
    local.asg_mf_outbound_xdelivery_lifecycle_hook_launching,
    local.asg_internet_delivery_lifecycle_hook_launching,
    local.asg_internet_xdelivery_lifecycle_hook_launching,
    local.asg_risky_delivery_lifecycle_hook_launching,
    local.asg_risky_xdelivery_lifecycle_hook_launching,
    local.asg_warmup_delivery_lifecycle_hook_launching,
    local.asg_warmup_xdelivery_lifecycle_hook_launching
  ]

  asg_instances_lifecycle_hook_terminating = [
    local.asg_delta_delivery_lifecycle_hook_terminating,
    local.asg_encryption_submit_lifecycle_hook_terminating,
    local.asg_encryption_delivery_lifecycle_hook_terminating,
    local.asg_customer_delivery_lifecycle_hook_terminating,
    local.asg_internet_submit_lifecycle_hook_terminating,
    local.asg_mf_inbound_delivery_lifecycle_hook_terminating,
    local.asg_mf_inbound_submit_lifecycle_hook_terminating,
    local.asg_mf_outbound_delivery_lifecycle_hook_terminating,
    local.asg_mf_outbound_submit_lifecycle_hook_terminating,
    local.asg_internet_delivery_lifecycle_hook_terminating,
    local.asg_customer_submit_lifecycle_hook_terminating,
    local.asg_risky_delivery_lifecycle_hook_terminating,
    local.asg_warmup_delivery_lifecycle_hook_terminating
  ]
}
