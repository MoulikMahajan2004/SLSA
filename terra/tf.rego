package pipeline

# Collect all root resources
all_resources contains r if {
  r := input.planned_values.root_module.resources[_]
}

# Collect child module resources if any exist
all_resources contains r if {
  module := input.planned_values.root_module.child_modules[_]
  r := module.resources[_]
} 

# EC2 instance type enforcement
deny contains msg if {
  r := all_resources[_]
  r.type == "aws_instance"
  r.values.instance_type != "t3.micro"

  msg := sprintf(
    "EC2 instance %s uses instance type %s. Research demo only allows t3.micro to reduce cost and risk.",
    [r.address, r.values.instance_type]
  )
}

# Public SSH IPv6
deny contains msg if {
  r := all_resources[_]
  r.type == "aws_security_group"

  ingress := r.values.ingress[_]
  ingress.from_port <= 22
  ingress.to_port >= 22
  ingress.ipv6_cidr_blocks[_] == "::/0"

  msg := sprintf(
    "Security group %s exposes SSH port 22 to ::/0. Restrict SSH to a trusted IPv6 address.",
    [r.address]
  )
}

# S3 public access block checks
deny contains msg if {
  r := all_resources[_]
  r.type == "aws_s3_bucket_public_access_block"
  r.values.block_public_acls != true

  msg := sprintf("S3 public access block %s must enable block_public_acls.", [r.address])
}

deny contains msg if {
  r := all_resources[_]
  r.type == "aws_s3_bucket_public_access_block"
  r.values.block_public_policy != true

  msg := sprintf("S3 public access block %s must enable block_public_policy.", [r.address])
}

deny contains msg if {
  r := all_resources[_]
  r.type == "aws_s3_bucket_public_access_block"
  r.values.ignore_public_acls != true

  msg := sprintf("S3 public access block %s must enable ignore_public_acls.", [r.address])
}

deny contains msg if {
  r := all_resources[_]
  r.type == "aws_s3_bucket_public_access_block"
  r.values.restrict_public_buckets != true

  msg := sprintf("S3 public access block %s must enable restrict_public_buckets.", [r.address])
}

# CloudWatch alarm must have SNS alarm action
deny contains msg if {
  r := all_resources[_]
  r.type == "aws_cloudwatch_metric_alarm"
  count(r.values.alarm_actions) == 0

  msg := sprintf(
    "CloudWatch alarm %s has no alarm_actions. Attach SNS topic for email notification.",
    [r.address]
  )
}











