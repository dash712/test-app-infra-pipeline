#!/bin/bash
RUN_TYPE=$(echo "$1")
ENVIRONMENT=$(echo "$2")
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
        printf "\e033[1;34mRunning palisade\e033[0m\n"
        palisade_results=$(../../palisade scan -t tfplan.json -d ../../policies)
        if [[ $palisade_results == "No violations found." ]]; then
            printf "\e033[31m$palisade_results\e033[0m\n"
            /usr/local/bin/terraform apply -auto-approve
        else
            echo "\033[1;34m$palisade_results\033[0m"
            exit 1;
        fi
        exit 0;
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
