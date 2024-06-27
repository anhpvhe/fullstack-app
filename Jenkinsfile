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
                        terraform output -raw ecr_backend_repository_url > ecr_backend_repository_url.txt
                        terraform output -raw ecr_frontend_repository_url > ecr_frontend_repository_url.txt
                        terraform output -raw ecr_database_repository_url > ecr_database_repository_url.txt
                        """
                    }
                    echo "Done initializing and applying terraform code"

                    // Read the output values from the files
                    env.EC2_INSTANCE_IP = readFile('terraform/ec2_instance_public_ip.txt').trim()
                    env.BACKEND_IMAGE = readFile('terraform/ecr_backend_repository_url.txt').trim()
                    env.FRONTEND_IMAGE = readFile('terraform/ecr_frontend_repository_url.txt').trim()
                    env.MYSQL_IMAGE = readFile('terraform/ecr_database_repository_url.txt').trim()
                    echo "Done stage Setup Infrastructure"
                }
            }
        }

        stage('Determine Changes') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    echo "Start stage Determine Changes"
                    // env.BACKEND_CHANGED = sh(script: "git diff --name-only HEAD~1 HEAD | grep '^backend/' | wc -l", returnStdout: true).trim()
                    // env.FRONTEND_CHANGED = sh(script: "git diff --name-only HEAD~1 HEAD | grep '^frontend/' | wc -l", returnStdout: true).trim()
                    // env.DATABASE_CHANGED = sh(script: "git diff --name-only HEAD~1 HEAD | grep '^database/' | wc -l", returnStdout: true).trim()

                    // Determine changes for each component
                    def backendChanged = bat(script: 'git diff --name-only HEAD~1 HEAD | findstr /R "^backend/" /C:"" /N | find /C ":"', returnStatus: true).trim()
                    def frontendChanged = bat(script: 'git diff --name-only HEAD~1 HEAD | findstr /R "^frontend/" /C:"" /N | find /C ":"', returnStatus: true).trim()
                    def databaseChanged = bat(script: 'git diff --name-only HEAD~1 HEAD | findstr /R "^database/" /C:"" /N | find /C ":"', returnStatus: true).trim()

                    // Write results to files
                    // writeFile file: "${env.WORKSPACE}/backend_changed.txt", text: backendChanged
                    // writeFile file: "${env.WORKSPACE}/frontend_changed.txt", text: frontendChanged
                    // writeFile file: "${env.WORKSPACE}/database_changed.txt", text: databaseChanged

                    // // Read values from files
                    // env.BACKEND_CHANGED = readFile("${env.WORKSPACE}/backend_changed.txt").trim()
                    // env.FRONTEND_CHANGED = readFile("${env.WORKSPACE}/frontend_changed.txt").trim()
                    // env.DATABASE_CHANGED = readFile("${env.WORKSPACE}/database_changed.txt").trim()

                    env.BACKEND_CHANGED = backendChanged.toInteger() > 0
                    env.FRONTEND_CHANGED = frontendChanged.toInteger() > 0
                    env.DATABASE_CHANGED = databaseChanged.toInteger() > 0
                    echo "Done stage Determine Changes"
                }
            }
        }

        stage('Build Docker Images') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            parallel {
                stage('Build Backend Image') {
                    when {
                        expression {
                            // return env.BACKEND_CHANGED.toInteger() > 0
                            return env.BACKEND_CHANGED
                        }
                    }
                    steps {
                        script {
                            echo "Start stage Build Backend Image"
                            bat 'cd fullstack-app\\backend && docker build -t spring-boot-backend .'
                            bat "docker tag spring-boot-backend:latest ${env.BACKEND_IMAGE}:latest"
                            echo "Done stage Build Backend Image"
                        }
                    }
                }
                stage('Build Frontend Image') {
                    when {
                        expression {
                            // return env.FRONTEND_CHANGED.toInteger() > 0
                            return env.FRONTEND_CHANGED
                        }
                    }
                    steps {
                        script {
                            echo "Start stage Build Frontend Image"
                            bat 'cd fullstack-app\\frontend && docker build -t react-frontend .'
                            bat "docker tag react-frontend:latest ${env.FRONTEND_IMAGE}:latest"
                            echo "Done stage Build Frontend Image"
                        }
                    }
                }
                stage('Build MySQL Image') {
                    when {
                        expression {
                            // return env.DATABASE_CHANGED.toInteger() > 0
                            return env.DATABASE_CHANGED
                        }
                    }
                    steps {
                        script {
                            echo "Start stage Build MySQL Image"
                            bat 'cd fullstack-app\\database && docker build -t mysql-database .'
                            bat "docker tag mysql-database:latest ${env.MYSQL_IMAGE}:latest"
                            echo "Start stage Build MySQL Image"
                        }
                    }
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

        stage('Push Images to ECR') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            parallel {
                stage('Push Backend Image') {
                    when {
                        expression {
                            // return env.BACKEND_CHANGED.toInteger() > 0
                            return env.BACKEND_CHANGED
                        }
                    }
                    steps {
                        script {
                            echo "Start stage Push Backend Image"
                            bat "docker push ${env.BACKEND_IMAGE}:latest"
                            echo "Done stage Push Backend Image"
                        }
                    }
                }
                stage('Push Frontend Image') {
                    when {
                        expression {
                            // return env.FRONTEND_CHANGED.toInteger() > 0
                            return env.FRONTEND_CHANGED
                        }
                    }
                    steps {
                        script {
                            echo "Start stage Push Frontend Image"
                            bat "docker push ${env.FRONTEND_IMAGE}:latest"
                            echo "Start stage Push Frontend Image"
                        }
                    }
                }
                stage('Push MySQL Image') {
                    when {
                        expression {
                            // return env.DATABASE_CHANGED.toInteger() > 0
                            return env.DATABASE_CHANGED
                        }
                    }
                    steps {
                        script {
                            echo "Start stage Push MySQL Image"
                            bat "docker push ${env.MYSQL_IMAGE}:latest"
                            echo "Done stage Push MySQL Image"
                        }
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    script {
                        echo "Start stage Deploy to EC2"
                        sh """
                        ssh -i ${SSH_KEY_PATH} ${SSH_USER}@${EC2_INSTANCE_IP} << 'EOF'
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        if [ ${env.BACKEND_CHANGED} -gt 0 ]; then
                            docker pull ${BACKEND_IMAGE}:latest
                            docker stop backend || true
                            docker rm backend || true
                            docker run -d --name backend --link mysql:mysql -p 8080:8080 ${BACKEND_IMAGE}:latest
                        fi
                        if [ ${env.FRONTEND_CHANGED} -gt 0 ]; then
                            docker pull ${FRONTEND_IMAGE}:latest
                            docker stop frontend || true
                            docker rm frontend || true
                            docker run -d --name frontend -p 80:80 ${FRONTEND_IMAGE}:latest
                        fi
                        if [ ${env.DATABASE_CHANGED} -gt 0 ]; then
                            docker pull ${MYSQL_IMAGE}:latest
                            docker stop mysql || true
                            docker rm mysql || true
                            docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=appdb ${MYSQL_IMAGE}:latest
                        fi
                        EOF
                        """
                        echo "Done stage Deploy to EC2"
                    }
                }
            }
        }
    }
}
