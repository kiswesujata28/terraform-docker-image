#!/usr/bin/env groovy

pipeline {
    agent {
		dockerfile {
			filename 'Dockerfile'
		}
	}

    environment {
        AWS = credentials("aws-iac-test")
	}

    parameters {
        booleanParam(defaultValue: false, description: 'Set Value to True to Initiate Destroy Stage', name: 'destroy')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        disableConcurrentBuilds()
    }

    stages {

        stage('TerraRising') {
            steps {

                 sh '''#!/bin/bash -le

                  echo "Start time: $(date)"
                  echo "AWS Account Information: ${AWS}"
                  subnet_values=$(echo "$subnet_values" | sed -r 's/\\\\"/"/g')
                  echo
                  echo -e "user_name:           \t\t\t ${user_name}"
                  echo -e "contact_email:       \t\t\t ${contact_email}"
                  echo -e "Created_By:          \t\t\t ${Created_by}"
                  echo -e "Created_Date:        \t\t\t $(date)"
                  echo -e "Jira_ticket_number:  \t\t\t ${Jira_ticket_Number}"
                  echo -e "Terraform Destroy:   \t\t\t ${destroy}"

                  echo " ### create tfvars ####"
                  mkdir -p variables

                  cut -d'|' -f2- << EOF > variables/terraform.tfvars
                    |user_name = "${user_name}"
                    | 
                    |tags = {
                    |  user_type = "${user_type}"
                    |  Created_By = "${Created_by}"
                    |  contact_email = "${contact_email}"
                    |  responsible_user = "${responsible_user}"
                    |  Jira_ticket_Number = "${Jira_ticket_Number}"
                    |}
EOF

                  echo " ### output tfvars ####"
                  cat variables/terraform.tfvars
                  echo "### end of tfvars ##### "
                  
                  cd <to-the-code-location>
                  echo -e "Run terraform version"
                  terraform --version
                  echo -e "Remove previous terraform directory"
                  rm -rf .terraform
                  echo -e "Run terraform init"

                  s3_bucket="test-bucket"
                  echo -e "S3 bucket: ${s3_bucket}"

                  dynamo_db_table="test-dynamo-table"
                  echo -e "Dynamo DB Table: ${dynamo_db_table}"

                  terraform init \
                    -no-color \
		            -input=false \
		            -force-copy \
		            -lock=true \
		            -upgrade \
		            -verify-plugins=true \
		            -backend=true \
		            -backend-config="region=us-east-1" \
		            -backend-config="bucket=${s3_bucket}" \
		            -backend-config="key=self-service/iam/${user_name}/iam_user.tfstate" \
		            -backend-config="dynamodb_table=${dynamo_db_table}" \
	                -backend-config="acl=private"

                   echo "End time: $(date)"
                   echo "=====End of Terraform Rising======="

                 '''
            }
        }


        stage('TerraPlanning') {
            when {
                 anyOf {
                expression { !params.destroy }
                }
            }

              steps {

                  sh '''#!/bin/bash -le
                    echo "## Terraform plan ### Start time: $(date)"

                    echo " ### output tfvars ####"
                    cat terraform/jenkins/self-service-iam-user/variables/terraform.tfvars
                    echo "### end of tfvars ##### "

                    cd terraform/jenkins/self-service-iam-user
                    terraform plan \
                        -no-color \
		                -lock=true \
		                -input=false \
		                -refresh=true \
		                -var-file=variables/terraform.tfvars\
		                -out=plan.tfplan

                    echo "End time: $(date)"
                    echo "=======End of Terraform Planning======="

                  '''
            }
        }



        stage("ValidateBeforeDeploy") {
            when {
                 allOf {
                    expression { !params.destroy }
                }
            }

            steps {
                input 'Are you sure you want to Deploy/Apply? Review the output of the previous step (plan) before proceeding!'
            }
        }



        stage('TerraApplying') {
            when {
                 allOf {
                    expression { !params.destroy }
                }
            }

            steps {
                sh '''#!/bin/bash -le
                  echo "======= Start of Terraform Apply========"
                  echo "Start time: $(date)"
                  cd terraform/jenkins/self-service-iam-user
                  terraform apply \
		            -no-color \
		            -lock=true \
		            -input=false \
		            -refresh=true \
		            plan.tfplan

                  echo "End time: $(date)"
                  echo "======= End of Terraform Apply========"

                  '''
            }
        }

        stage('TerraDestoryPlanning') {
            when {
                 anyOf {
                expression { params.destroy }
                }
            }

              steps {
                  sh '''#!/bin/bash -le

                    echo "## Terraform plan ### Start time: $(date)"
                    echo " ### output tfvars ####"
                    cat terraform/jenkins/self-service-iam-user/variables/terraform.tfvars
                    echo "### end of tfvars ##### "
                    cd terraform/jenkins/self-service-iam-user
                    terraform plan \
                        -no-color \
		                -lock=true \
		                -input=false \
		                -refresh=true \
		                -var-file=variables/terraform.tfvars \
                        -destroy \
		                -out=destroy.tfplan

                    echo "End time: $(date)"
                    echo "=======End of Terraform Planning======="

                  '''
            }
        }

        stage("ValidateBeforeDestroy") {
            when {
                 allOf {
                    expression { params.destroy }
                }
            }

            steps {
                input 'Are you sure you want to DESTROY/DELETE? Carefully review the output of the previous DESTROY (plan) before proceeding!'
            }
        }

        stage('TerraDestroy') {
            when {
                 allOf {
                    expression { params.destroy }
                }
            }

            steps {
                echo "=========== Terraform DESTROY ======="

                sh '''#!/bin/bash -le

                  echo "Start time: $(date)"
                  cd terraform/jenkins/self-service-iam-user
                  terraform destroy \
                    -no-color \
		            -lock=true \
                    -var-file=variables/terraform.tfvars \
                    -auto-approve

                  echo "End time: $(date)"
                  echo "=======End of Terraform DESTROY ========"

                  '''
            }
        }
    }
}
