package terraform.ssh_access

deny[reason]{
    resource :=  input.resource_changes[_];
    resource.type == "aws_security_group";
    resource.change.after.ingress[_].protocol == "ssh"
    resource.change.after.ingress[_].to_port == 22
    reason := sprintf(
    "%s: Ingress SSH Access not allowed into %s.",
    [resource.address, resource.name]
    )
}