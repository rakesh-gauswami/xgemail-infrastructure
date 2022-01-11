locals {
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD  = 900
  DEFAULT_INSTANCE_SIZE                 = "t2.small"
  DEFAULT_EBS_SIZE_DATA_GB          = 10
  DEFAULT_ZONE_INDEX = {
    1 = 0
    2 = 1
    3 = 2
  }

  DEFAULT_AS_MIN_SIZE = {
    1 = 1
    2 = 0
    3 = 0
  }

  AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT = {
    inf  = 2400
    dev  = 2400
    qa   = 2400
    prod = 2400
  }

  EBS_SIZE_DATA_GB_BY_ENVIRONMENT = {
    inf  = 10
    dev  = 40
    qa   = 70
    prod = 100
  }

  INSTANCE_SIZE_BY_ENVIRONMENT = {
    inf  = "t2.small"
    dev  = "c4.xlarge"
    qa   = "c4.xlarge"
    prod = "m5.2xlarge"
  }

  AS_MIN_SIZE_BY_ENVIRONMENT = {
    inf  = {
      1 = 1
      2 = 0
      3 = 0
    }
    dev  = {
      1 = 1
      2 = 0
      3 = 0
    }
    qa   = {
      1 = 1
      2 = 0
      3 = 0
    }
    prod = {
      1 = 1
      2 = 0
      3 = 0
    }
  }

  ZONE_INDEX_BY_ENVIRONMENT = {
    inf  = {
      1 = 0
      2 = 1
      3 = 2
    }
    dev  = {
      1 = 0
      2 = 1
      3 = 2
    }
    qa   = {
      1 = 0
      2 = 1
      3 = 2
    }
    prod = {
      1 = 0
      2 = 1
      3 = 2
    }
  }

  as_min_size = lookup(
    local.AS_MIN_SIZE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_MIN_SIZE
  )

  ebs_size_data_gb = lookup(
    local.EBS_SIZE_DATA_GB_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_EBS_SIZE_DATA_GB
  )

  health_check_grace_period = lookup(
    local.AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD
  )

  instance_size = lookup(
    local.INSTANCE_SIZE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_INSTANCE_SIZE
  )

  zone_index = lookup(
    local.ZONE_INDEX_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_ZONE_INDEX
  )
}

resource "aws_cloudformation_stack" "cloudformation_stack" {
  for_each      = local.zone_index
  name          = "${local.instance_type}-${each.key}"
  template_body = file("${path.module}/templates/as_customer_xdelivery_template.json")

  parameters = {
    AccountName                       = local.input_param_account_name
    AmiId                             = data.aws_ami.ami.id
    AutoScalingMinSize                = local.as_min_size[each.key]
    AutoScalingMaxSize                = 1
    AutoScalingNotificationTopicARN   = local.input_param_lifecycle_topic_arn
    AvailabilityZoneIndex             = each.value
    AvailabilityZones                 = local.input_param_availability_zones
    Branch                            = var.build_branch
    BuildTag                          = var.build_tag
    BuildUrl                          = var.build_url
    BundleVersion                     = local.ami_build
    EbsMinIops                        = 0
    EbsMinSizeDataGB                  = local.ebs_size_data_gb
    Environment                       = local.input_param_deployment_environment
    HealthCheckGracePeriod            = local.health_check_grace_period
    InstanceProfile                   = local.input_param_iam_instance_profile_arn
    InstanceType                      = local.instance_size
    KmsKeyAlias                       = module.kms_key.key_alias_name
    LifecycleHookLaunching            = local.input_param_lifecycle_hook_launching
    LoadBalancerName                  = aws_elb.elb.id
    MsgHistoryStatusQueueUrl          = var.message_history_status_sqs_queue
    MsgHistoryStatusSnsArn            = var.message_history_status_sns_topic
    MsgHistoryV2BucketName            = var.message_history_ms_bucket
    MsgHistoryV2DynamoDbTableName     = var.message_history_dynamodb_table_name
    MsgHistoryV2StreamName            = var.message_history_v2_stream_name
    ParentAccountName                 = local.input_param_parent_account_name
    PolicyBucketName                  = var.policy_bucket
    S3CookbookRepositoryURL           = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/${var.build_number}/cookbooks.tar.gz"
    SecurityGroups                    = aws_security_group.security_group_ec2.id
    SpotPrice                         = "-1"
    StationVpcId                      = var.station_vpc_id
    StationVpcName                    = replace(var.station_name, "/-.*/", "")
    VolumeSetId                       = "${local.instance_type}-${each.key}"
    VolumeTrackerSimpleDbDomain       = local.input_param_sdb_volume_tracker_name
    Vpc                               = local.input_param_vpc_id
    VpcZoneIdentifiers                = join(",", local.input_param_public_subnet_ids)
    VpcName                           = local.input_param_vpc_name
    XgemailServiceType                = local.instance_type
  }
}
