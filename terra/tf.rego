package pipeline

# -----------------------
# Helpers
# -----------------------

# all_resources contains r if {
#   r := input.planned_values.root_module.resources[_]
# }
deny contains msg if {
  r := input.planned_values.root_module.resources[_]
  r.type == "aws_instance"
  r.mode =="unmanaged"
  msg:= sprintf("Resource %s of type %s in mode %s", [r.address, r.type, r.mode])
}

# ec2_instances contains r if {
#   r := all_resources[_]
#   r.type == "aws_instance"
# }
#adding comment simply to check the pipeloine commits 
# # Safe helper: treat missing value as false

# # created a small function 
# has_public_ip(r) if {
#   r.values.associate_public_ip_address == true
# }

# public_approved(r) if {
#   r.values.tags.exposure == "public-approved"
# }

# # -----------------------
# # Policy
# # -----------------------

# deny contains msg if {
#   r := ec2_instances[_]
# #   entering the argument r into the funcation 
#  not( has_public_ip(r))
# #   not public_approved(r)

#   msg := sprintf("EC2 %s has a public IP but is not approved (add tag exposure=public-approved or remove public IP).", [r.address])
# }


