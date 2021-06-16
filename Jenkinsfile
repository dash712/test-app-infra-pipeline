node {
    checkout scm
    def props = readYaml file: "terraform/deploy_env/infra-parameters.yaml"
    properties([
        parameters([
            string(name: 'APP_NAME', defaultValue: props.PARAMETERS.APP_NAME, description: 'Application Name'),
            string(name: 'RUN_TYPE', defaultValue: props.PARAMETERS.RUN_TYPE, description: 'Terraform run type, such as plan, destroy or apply'),
            string(name: 'ENVIRONMENT', defaultValue: props.PARAMETERS.ENVIRONMENT, description: 'dev, sit, uat or prod'),
            string(name: 'DEPLOYMENT_REGION', defaultValue: props.PARAMETERS.DEPLOYMENT_REGION, description: 'AWS deployment region'),
            booleanParam(name: 'SG', defaultValue: props.PARAMETERS.SG, description: 'Whether to run security groups tf code'),
            booleanParam(name: 'RDS', defaultValue: props.PARAMETERS.RDS, description: 'Whether to run rds tf code'),
            booleanParam(name: 'IAM', defaultValue: props.PARAMETERS.IAM, description: 'Whether to run iam tf code')
        ])
    ])
}
pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr:'100'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }
    stages {
        stage('Initialization') {
            steps {
                script{
                    env.APP_NAME =  "${params.APP_NAME}"
                    env.RUN_TYPE =  "${params.RUN_TYPE}"
                    env.ENVIRONMENT =  "${params.ENVIRONMENT}"
                    env.DEPLOYMENT_REGION =  "${params.DEPLOYMENT_REGION}"
                    env.SG = "${params.SG}"
                    env.RDS = "${params.RDS}"
                    env.IAM =  "${params.IAM}"
                }
            }
        }
        stage('RDS'){
            when {
                expression { params.RDS == true}
            }
            steps {
                script{
                    sh'''#!/bin/bash
                    set -e 
                    ls
                    chmod +x ../terraform/deploy_env/terraform.sh
                    ../terraform/deploy_env/terraform.sh $RUN_TYPE $ENVIRONMENT $DEPLOYMENT_REGION $APP_NAME ecr
                    '''
                }
            }
        }
        stage('IAM'){
            when {
                expression { params.IAM == true}
            }
            steps {
                script{
                    sh'''#!/bin/bash
                    set -e 
                    chmod +x terraform/deploy_env/terraform.sh
                    terraform/deploy_env/terraform.sh $RUN_TYPE $ENVIRONMENT $DEPLOYMENT_REGION $APP_NAME iam
                    '''
                }
            }
        }
        stage('SG'){
            when {
                expression { params.SG == true}
            }
            steps {
                 withAWS(credentials: 'palisade-test-credentials', region: 'us-east-1') {
                    script {
                    sh'''#!/bin/bash
                    set -e 
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
                    '''
                    }
                 }
                // chmod +x terraform/deploy_env/terraform.sh
                // terraform/deploy_env/terraform.sh $RUN_TYPE $ENVIRONMENT $DEPLOYMENT_REGION $APP_NAME $SG
            }
        }
    }
}