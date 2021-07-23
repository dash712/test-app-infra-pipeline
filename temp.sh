                    RUN_TYPE=apply
                    ENVIRONMENT=prod
                    DEPLOYMENT_REGION=us-east-1
                    APP_NAME=palisade-test
                    MODULE=sg
                    VAR_FOLDER="$ENVIRONMENT-$DEPLOYMENT_REGION"
                    KEY="applications/$APP_NAME/$MODULE_TYPE/terraform.tfstate"
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
                        if [[ ($ENVIRONMENT == "uat" || $ENVIRONMENT == "prod") && $MODULE == "sg" ]]; then 
                            echo "\033[1;34mRunning palisade\033[0m"
                            # /usr/local/bin/opa eval --format pretty -b . --input tfplan.json 
                            cd ../..
                            python3 -m venv env
                            source env/bin/activate
                            pip3 install python-hcl2 --quiet --disable-pip-version-check
                            PALISADE_RESULT=$(python3 parser.py)
                            if [[ $PALISADE_RESULT != "Your terraform code is in compliance." ]]; then
                                echo "\033[31m${PALISADE_RESULT} \033[0m"
                                exit 1;
                            else
                                echo "\033[1;34m${PALISADE_RESULT} \033[0m"
                                cd terraform/$MODULE
                                /usr/local/bin/terraform apply -auto-approve
                            fi 
                            deactivate
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