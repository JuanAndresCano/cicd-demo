pipeline {
    agent any

    environment {
        APP_NAME   = 'cicd-demo'
        DOCKER_TAG = 'latest'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests -B'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test -B -DforkCount=0 -Dexcludes="**/SeleniumExampleTest.java"'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Static Analysis (SonarQube)') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar -Dsonar.projectKey=cicd-demo -B'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t ${APP_NAME}:${DOCKER_TAG} .'
            }
        }

        stage('Container Security Scan (Trivy)') {
            steps {
                sh '''
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/trivy \
                        aquasec/trivy image \
                            --exit-code 1 \
                            --severity CRITICAL \
                            --no-progress \
                            ${APP_NAME}:${DOCKER_TAG}
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker stop ${APP_NAME} || true
                    docker rm   ${APP_NAME} || true
                    docker run -d \
                        --name ${APP_NAME} \
                        -p 80:8081 \
                        ${APP_NAME}:${DOCKER_TAG}
                '''
            }
        }
    }

    post {
        always {
            echo 'Limpiando espacio de trabajo...'
            cleanWs()
        }
        success {
            echo 'Pipeline completado exitosamente.'
        }
        failure {
            echo 'Pipeline falló. Revisa el stage en rojo.'
        }
    }
}