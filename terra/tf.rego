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

# Detect unmanaged EC2 resources
deny contains msg if {
  r := all_resources[_]
  r.type == "aws_instance"
  r.mode == "unmanaged"

  msg := sprintf(
    "Resource %s of type %s is unmanaged.",
    [r.address, r.type]
  )
}

# Public SSH IPv4
# deny contains msg if {
#   r := all_resources[_]
#   r.type == "aws_security_group"

#   ingress := r.values.ingress[_]
#   ingress.from_port <= 22
#   ingress.to_port >= 22
#   ingress.cidr_blocks[_] == "0.0.0.0/0"

#   msg := sprintf(
#     "Security group %s exposes SSH port 22 to 0.0.0.0/0. Restrict SSH to a trusted IP address.",
#     [r.address]
#   )
# }

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

















# package pipeline


# #ec2 OPA POLICY
# #setting the t3.micro as the only allowed instance type for the research demo to reduce cost and risk of using larger instances.
# deny contains msg if {
#   r := all_resources[_]
#   r.type == "aws_instance"
#   not r.values.instance_type == "t3.micro"
#   msg := sprintf("EC2 instance %s uses instance type %s. Research demo only allows t3.micro to reduce cost and risk.", [r.address, r.values.instance_type])
# }

# #--DETECTING IF ANY UNAMANGED INSTANCE 
# deny contains msg if {
#   r := input.planned_values.root_module.resources[_]
#   r.type == "aws_instance"
#   r.mode =="unmanaged"
#   msg:= sprintf("Resource %s of type %s in mode %s", [r.address, r.type, r.mode])
# }
# #SECURITY GROUP OPA POLICY

# # True if a CIDR block is public/open to the internet
# is_public_cidr(cidr) if {
#   cidr == "0.0.0.0/0"
# }

# is_public_ipv6_cidr(cidr) if {
#   cidr == "::/0"
# }

# deny contains msg if {
#   r := all_resources[_]
#   r.type == "aws_security_group"
#   ingress := r.values.ingress[_]
#   ingress.from_port <= 22
#   ingress.to_port >= 22
#   cidr := ingress.cidr_blocks[_]
#   is_public_cidr(cidr)
#   msg := sprintf("Security group %s exposes SSH port 22 to 0.0.0.0/0. Restrict SSH to a trusted IP address.", [r.address])
# }


# deny contains msg if {
#   r := all_resources[_]
#   r.type == "aws_security_group"
#   ingress := r.values.ingress[_]
#   ingress.from_port <= 22
#   ingress.to_port >= 22
#   cidr := ingress.ipv6_cidr_blocks[_]
#   is_public_ipv6_cidr(cidr)
#   msg := sprintf("Security group %s exposes SSH port 22 to ::/0. Restrict SSH to a trusted IPv6 address.", [r.address])
# }

# #S3

# deny contains msg if {
#   r := all_resources[_]
#   r.type == "aws_s3_bucket_public_access_block"
#   not r.values.block_public_acls == true
#   msg := sprintf("S3 public access block %s must enable block_public_acls.", [r.address])
# }

# deny contains msg if {
#   r := all_resources[_]
#   r.type == "aws_s3_bucket_public_access_block"
#   not r.values.block_public_policy == true
#   msg := sprintf("S3 public access block %s must enable block_public_policy.", [r.address])
# }

# deny contains msg if {
#   r := all_resources[_]
#   r.type == "aws_s3_bucket_public_access_block"
#   not r.values.ignore_public_acls == true
#   msg := sprintf("S3 public access block %s must enable ignore_public_acls.", [r.address])
# }

# deny contains msg if {
#   r := all_resources[_]
#   r.type == "aws_s3_bucket_public_access_block"
#   not r.values.restrict_public_buckets == true
#   msg := sprintf("S3 public access block %s must enable restrict_public_buckets.", [r.address])
# }

# #CLOUD TRAIL BUCKET ENCRYPTION OPA POLICY
# deny contains msg if {
#   bucket := all_resources[_]
#   bucket.type == "aws_s3_bucket"
#   contains(bucket.address, "cloudtrail")
#   not encryption_exists_for_bucket(bucket.values.bucket)
#   msg := sprintf("CloudTrail S3 bucket %s does not have server-side encryption configured.", [bucket.address])
# }

# encryption_exists_for_bucket(bucket_name) if {
#   enc := all_resources[_]
#   enc.type == "aws_s3_bucket_server_side_encryption_configuration"
#   enc.values.bucket == bucket_name
# }

# deny contains msg if {
#   bucket := all_resources[_]
#   bucket.type == "aws_s3_bucket"
#   contains(bucket.address, "cloudtrail")
#   not versioning_enabled_for_bucket(bucket.values.bucket)
#   msg := sprintf("CloudTrail S3 bucket %s does not have versioning enabled.", [bucket.address])
# }

# versioning_enabled_for_bucket(bucket_name) if {
#   v := all_resources[_]
#   v.type == "aws_s3_bucket_versioning"
#   v.values.bucket == bucket_name
#   v.values.versioning_configuration[0].status == "Enabled"
# }
# #SNS ENFORCEMENT 

# deny contains msg if {
#   r := all_resources[_]
#   r.type == "aws_cloudwatch_metric_alarm"
#   count(r.values.alarm_actions) == 0
#   msg := sprintf("CloudWatch alarm %s has no alarm_actions. Attach SNS topic for email notification.", [r.address])
# }


# # ec2_instances contains r if {
# #   r := all_resources[_]
# #   r.type == "aws_instance"
# # }
# #adding comment simply to check the pipeloine commits 
# # # Safe helper: treat missing value as false

# # # created a small function 
# # has_public_ip(r) if {
# #   r.values.associate_public_ip_address == true
# # }

# # public_approved(r) if {
# #   r.values.tags.exposure == "public-approved"
# # }

# # # -----------------------
# # # Policy
# # # -----------------------

# # deny contains msg if {
# #   r := ec2_instances[_]
# # #   entering the argument r into the funcation 
# #  not( has_public_ip(r))
# # #   not public_approved(r)

# #   msg := sprintf("EC2 %s has a public IP but is not approved (add tag exposure=public-approved or remove public IP).", [r.address])
# # }


