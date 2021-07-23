#!/bin/bash
RUN_TYPE=$(echo "$1" | tr '[:upper]' '[:lower]')
ENVIRONMENT=$(echo "$2" | tr '[:upper]' '[:lower]')
DEPLOYMENT_REGION=$(echo "$3" | tr '[:upper]' '[:lower]')
APP_NAME=$(echo "$4" | tr '[:upper]' '[:lower]')
MODULE=$(echo "$5" | tr '[:upper]' '[:lower]')
# VAR-FOLDER=$ENVIRONMENT-$DEPLOYMENT_REGION
# KEY="applications/$APP_NAME/$MODULE_TYPE/terraform.tfstate"

cd terraform/$MODULE || exit 1
/usr/local/bin/terraform init \
-input=false \
-backend=true \
-backend-config="bucket=terraform-state-$ENVIRONMENT-$DEPLOYMENT_REGION" \
-backend-config="region=$REGION" \
-get=true

case $RUN_TYPE in

"plan")
    /usr/local/bin/terraform plan -out=tfplan -input=false
    ;;

"apply")
    /usr/local/bin/terraform plan -out=tfplan.binary -input=false
    /usr/local/bin/terraform show -json tfplan.binary > tfplan.json
    if [[ ($ENVIRONMENT == "uat" || $ENVIRONMENT == "prod") && $MODULE == "sg" ]]; then 
        echo "Running palisade"
        ../palisade -t "tfplan.json" -d "../policies" 
        exit 0;
        # Run palisade 
        # palisade needs to be passed a tfplan.json, global policy, and application-specific policy in YAML/JSON format 

        # if palisade returns policy violation; exit 1; else continue to terraform apply 
    else
        /usr/local/bin/terraform apply -auto-approve
    fi 
    ;;

"destroy")
    /usr/local/bin/terraform destroy -force
    ;;

*)
    echo "Invalid action"
    exit 1
    ;;
esac
