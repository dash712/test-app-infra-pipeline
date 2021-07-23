package terraform.allowed_resources
  
allowed_resources = [
"aws_s3_bucket"
]
 
 
array_contains(arr, elem) {
arr[_] = elem
}
 
deny[reason] {
  resource := input.resource_changes[_]
  action := resource.change.actions[count(resource.change.actions) - 1]
  array_contains(["create", "update"], action)
  
  not array_contains(allowed_resources, resource.type)
  
  result := {
      "description" : "resource type is not allowed",
      "resource": resource.address,
  }
  reason := result
}