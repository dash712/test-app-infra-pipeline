import hcl2
import json 
import re


# parameters: --folder --global-permissions --local-permissions 

with open('terraform/sg/main.tf', 'r') as terraform_file:
    resources = hcl2.load(terraform_file)
with open('standard/permissions.json', 'r' ) as permissions_file:
    permissions = json.load(permissions_file)
with open('terraform/sg/permissions.json', 'r' ) as local_permissions_file:
    local_permissions = json.load(local_permissions_file)

security_group_name = resources['resource'][0]['aws_security_group']['palisade-test-sg']['name'][0]
global_rule_name = permissions[0]['terraform'][0]['aws_security_group'][0]['name']
local_rule_name = local_permissions[0]['terraform'][0]['aws_security_group'][0]['name']

if re.match(rf"{global_rule_name}", security_group_name):
    print ("Your terraform code is in compliance.")
elif re.match(rf"{local_rule_name}", security_group_name):
    print ("Your terraform code is in compliance.")
else:
    print(f"{security_group_name} is not in compliance. Please fix.")
