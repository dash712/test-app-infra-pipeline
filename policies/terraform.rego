package terraform.sg_allow

import data.tf_resources.security_groups as tf_security_groups

default pass = false

#set of allowed security group names, need to look at passing these in at runtime if possible.
allowed_names := {"good_sg", "good_sg_2"}

#getting all security group names
security_group_names = all {
   all := { name |
      name := tf_security_groups[_].name
   }
}

security_group_data = { group.name : group.address |
  group := tf_security_groups[_]
}

#set operation
names_not_in_allowed_names := security_group_names - allowed_names

deny [reason] {
    count(names_not_in_allowed_names) > 0
    result = { name: reporting |
      name := names_not_in_allowed_names[_]
      reporting := {"name": name, "resource address": security_group_data[name], "description": "security group not in approved list"}
    } 
    reason := result
}

#check the number of denies, in this case there is only one.  if we fail, this evaluate as false
pass {                                      
  count(deny) == 0                          
}

#number of denies
deny_count [deny_count] {
  deny_count := count(deny)
}
