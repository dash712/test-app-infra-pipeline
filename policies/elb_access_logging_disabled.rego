package terraform.elb_access_logging_disabled

deny[reason]{
    resource :=  input.resource_changes[_]
    resource.type == "aws_lb"
    resource.change.after.access_logs[_].enabled == false
    result := {
        "description" : "aws_lb resources must have access logs enabled.",
        "resource": resource.address,
    }
    reason := result
}