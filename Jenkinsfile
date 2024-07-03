pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        //ECR_REGISTRY_ID = credentials('ECR_REGISTRY_ID')  // Default value if credential not found '975050200537'
        //ECR_REGISTRY = "${ECR_REGISTRY_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REGISTRY = "975050200537.dkr.ecr.${AWS_REGION}.amazonaws.com"
        SSH_USER = 'ec2-user'
        SSH_KEY_PATH = "${env.WORKSPACE}/key/key.pem"
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        SSH_PUBLIC_KEY = credentials('SSH_PUBLIC_KEY')
        EC2_SSH_KEY = credentials('ec2-ssh-key')
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Start stage Checkout"
                    checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: 'https://github.com/anhpvhe/fullstack-app.git']]])
                    echo "Done stage Checkout"
                }
            }
        }

        stage('Setup Infrastructure') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    echo "Start stage Setup Infrastructure"
                    // Write the public and private keys to files
                    writeFile file: "${env.WORKSPACE}/key/key.pub", text: env.SSH_PUBLIC_KEY
                    echo "Done writing public key file"
                    writeFile file: "${env.WORKSPACE}/key/key.pem", text: env.EC2_SSH_KEY
                    echo "Done writing ssh key file"

                    // Change the file permissions of key.pem to be more secure (cross-platform)
                    if (isUnix()) {
                        sh 'chmod 600 ${env.WORKSPACE}/key/key.pem'
                    } else {
                        bat """
                        @echo off
                        icacls ${env.WORKSPACE}\\key\\key.pem /inheritance:r
                        icacls ${env.WORKSPACE}\\key\\key.pem /grant:r %USERNAME%:F
                        icacls ${env.WORKSPACE}\\key\\key.pem /remove:g Administrators SYSTEM Everyone
                        """
                    }
                    echo "Done updating key permission"

                    dir('terraform') {
                        bat """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        terraform init -reconfigure -backend-config="bucket=your-unique-bucket-name-anhpvhe17" -backend-config="key=terraform/state" -backend-config="region=%AWS_REGION%" -backend-config="dynamodb_table=terraform-locks"
                        terraform apply -auto-approve
                        terraform output -raw ec2_instance_public_ip > ec2_instance_public_ip.txt
                        terraform output -raw ecr_frontend_repository_url > ecr_frontend_repository_url.txt
                        """
                    }
                    echo "Done initializing and applying terraform code"

                    // Read the output values from the files
                    env.EC2_INSTANCE_IP = readFile('terraform/ec2_instance_public_ip.txt').trim()
                    env.FRONTEND_IMAGE = readFile('terraform/ecr_frontend_repository_url.txt').trim()
                    // env.EC2_INSTANCE_IP = bat(script: 'cd terraform && terraform output -raw ec2_instance_public_ip', returnStdout: true).trim()
                    // env.FRONTEND_IMAGE = bat(script: 'cd terraform && terraform output -raw ecr_frontend_repository_url', returnStdout: true).trim()
                    // echo "${env.EC2_INSTANCE_IP}"
                    echo "Done stage Setup Infrastructure"
                }
            }
        }

        stage('Build Docker Image') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    echo "Start stage Build Docker Image"
                    bat 'cd fullstack-app\\frontend && docker build -t react-frontend .'
                    echo "Done stage Build Docker Image"
                }
            }
        }
        stage('Tag Docker Image'){
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps{
                script {
                    echo "Start stage Tag Docker Image"
                    bat "docker tag react-frontend:latest ${env.FRONTEND_IMAGE}:latest"
                    echo "Done stage Tag Docker Image"
                }
            }
        }

        stage('Login to AWS ECR') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    echo "Start stage Login to AWS ECR"
                    bat """
                    set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                    set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                    aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REGISTRY%
                    """
                    echo "Done stage Login to AWS ECR"
                }
            }
        }

        stage('Push Image to ECR') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    echo "Start stage Push Image to AWS ECR"
                    bat "docker push ${env.FRONTEND_IMAGE}:latest"
                    // echo "${SSH_KEY_PATH}"
                    // echo "${SSH_USER}"
                    // echo "${env.EC2_INSTANCE_IP}"
                    echo "Done stage Push Image to AWS ECR"
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps{
                script {
                    echo "Start stage Deploy to EC2"
                    def sshCommand = """
                        sudo yum update -y &&
                        sudo yum install docker -y &&
                        sudo systemctl start docker &&
                        sudo systemctl enable docker &&
                        sudo usermod -aG docker ${SSH_USER} &&
                        aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID} &&
                        aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY} &&
                        aws configure set default.region ${AWS_REGION} &&
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY} &&
                        docker pull ${FRONTEND_IMAGE}:latest &&
                        docker stop frontend || true &&
                        docker rm frontend || true &&
                        docker run -d --name frontend -p 80:80 ${FRONTEND_IMAGE}:latest
                    """
        
                    bat """
                    @echo off
                    ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ${SSH_USER}@${EC2_INSTANCE_IP} "%sshCommand%"
                    """
                    echo "Done stage Deploy to EC2"
                }
            }
        }
    }
}
