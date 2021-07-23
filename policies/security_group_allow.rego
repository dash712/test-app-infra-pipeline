package terraform.security_group_allow

allowed_names := {"good_sg"}

security_groups := { name |
	  name := input.resource_changes[_]
    name.type == "aws_security_group"
}

security_group_names = all {
   all := { name |
      name := security_groups[_].name
   }
}

security_group_data = { group.name : group.address |
  group := security_groups[_]

}

names_not_in_allowed_names := security_group_names - allowed_names

deny [reason] {
    count(names_not_in_allowed_names) > 0
    result := {
        "description" : "security groups not in approved list",
        "security_group_names" : names_not_in_allowed_names  
    } 
    reason := result
}

# deny [reason] {
#     count(names_not_in_allowed_names) > 0
#     result = { name: address |
#       name := names_not_in_allowed_names[_]
#       address := {"resource address": security_group_data[name], "description": "security group not in approved list"}
#     } 
#     reason := result
# }

default test_condition = false

test_condition {                                      # allow is true if...
    count(deny) == 0                           # there are zero violations.
}