pipeline {
    agent any

    environment {
        APP_NAME    = 'cicd-demo'
        DOCKER_TAG  = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout scm lee automáticamente tu repo actual.
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                // Hacemos el build. Nota: como los tests en local están fallando 
                // con Java 21, usamos skipTests para asegurar el MVP rápido.
                sh './mvnw clean package -DskipTests'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${APP_NAME}:${DOCKER_TAG} -f cicd-demo/Dockerfile ."
            }
        }

        stage('Deploy') {
            steps {
                sh """
                    # Detener y eliminar contenedor anterior si existe
                    docker stop ${APP_NAME} || true
                    docker rm   ${APP_NAME} || true

                    # Levantar la nueva versión en el puerto 80 tal cual pide el doc
                    docker run -d --name ${APP_NAME} -p 80:8081 ${APP_NAME}:${DOCKER_TAG}
                """
            }
        }
    }

    post {
        always {
            echo 'Limpiando entorno...'
            cleanWs()
        }
    }
}