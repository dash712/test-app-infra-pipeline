package tf_resources

import input as tfplan

tf_plan_resources [resources] {
    resources := tfplan.resource_changes[_]
}

#getting all security groups
security_groups := { name |
    name := tf_plan_resources[_]
    name.type == "aws_security_group"
}
