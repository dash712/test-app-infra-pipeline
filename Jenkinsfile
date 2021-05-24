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
    agent { label 'any' }
    options {
        buildDiscarder(logRotator(numToKeepStr:'100'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }
    stages {
        stage('Initialization') {
            agent { label 'any'}
            steps {
                deleteDir()
                script{
                    env.APP_NAME =  "${params.APP_NAME}"
                    env.RUN_TYPE =  "${params.RUN_TYPE}"
                    env.ENVIRONMENT =  "${params.ENVIRONMENT}"
                    env.DEPLOYMENT_REGION =  "${params.DEPLOYMENT_REGION}"
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
                    chmod +x terraform/deploy_env/terraform.sh
                    terraform/deploy_env/terraform.sh $RUN_TYPE $ENVIRONMENT $DEPLOYMENT_REGION $APP_NAME ecr
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
        stage('OPA'){
            steps {
                script{
                    sh'''#!/bin/bash
                    ###pulling down binary for opa.  if there is a more appropriate place to peform this, shift to there.
                    set -e
                    curl -L -o opa https://openpolicyagent.org/downloads/v0.28.0/opa_linux_amd64
                    chmod +x ./opa
                    '''
                }

            }

        }
        stage('SG'){
            when {
                expression { params.SG == true}
            }
            steps {
                script{
                    sh'''#!/bin/bash
                    set -e 
                    # This shell script will prep terraform env, create a tf plan, then call our binary. 
                    # will return failure code if a policy violation is found in upper environments and a warning in dev environment.
                    /var/lib/jenkins/deployer/deploy-sg.sh $RUN_TYPE $ENVIRONMENT $DEPLOYMENT_REGION $APP_NAME iam
                    '''
                }
            }
        }
    }
}