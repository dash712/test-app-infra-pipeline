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
                 withAWS(credentials: 'palisade-test-credentials', region: params.DEPLOYMENT_REGION) {
                    script {
                    sh'''#!/bin/bash
                    set -e 
                    chmod +x terraform/deploy_env/terraform.sh
                    echo $RUN_TYPE
                    terraform/deploy_env/terraform.sh $RUN_TYPE $ENVIRONMENT $DEPLOYMENT_REGION $APP_NAME sg
                    '''
                    }
                 }        
            }
        }
    }
}