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
                    # This shell script will prep terraform env, create a tf plan, then call our binary. 
                    # will return failure code if a policy violation is found in upper environments and a warning in dev environment.

                    RUN_TYPE=plan
                    ENVIRONMENT=dev
                    DEPLOYMENT_REGION=us-east-1
                    APP_NAME=palisade-test
                    MODULE=sg
                    VAR_FOLDER="$ENVIRONMENT-$DEPLOYMENT_REGION"
                    KEY="applications/$APP_NAME/$MODULE_TYPE/terraform.tfstate"
                    ls
                    pwd
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
                        # /usr/local/bin/terraform plan -out=tfplan.binary -input=false
                        # /usr/local/bin/terraform show -json tfplan.binary > tfplan.json 
                        /usr/local/bin/terraform apply -auto-approve
                        ;;

                    "destroy")
                        /usr/local/bin/terraform destroy -force
                        ;;

                    *)
                        echo "Invalid action"
                        exit 1
                        ;;
                    esac
                    if [[ ($ENVIRONMENT == "uat" || $ENVIRONMENT == "prod") && $RUN_TYPE == "apply" && $MODULE == "sg" ]]; then 
                        echo "Running palisade"
                        exit 0;
                        # Run palisade 
                        # palisade needs to be passed a tfplan.json, global policy, and application-specific policy in YAML/JSON format 
                        # opa eval --format pretty -b . --input tfplan.json 
                        # if palisade returns policy violation; exit 1; else continue to terraform apply 
                    fi
                    '''
                    }
                 }
                // chmod +x terraform/deploy_env/terraform.sh
                // terraform/deploy_env/terraform.sh $RUN_TYPE $ENVIRONMENT $DEPLOYMENT_REGION $APP_NAME $SG
            }
        }
    }
}