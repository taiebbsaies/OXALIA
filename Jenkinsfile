pipeline {
    agent any

    environment {
    BACKEND_DIR = 'oxalia_back'
    DATABASE_URL = 'postgresql+asyncpg://postgres:postgres@localhost:5432/oxalia'
    JWT_SECRET_KEY = 'ci-test-secret-key-32-bytes-minimum!!'
    JWT_ALGORITHM = 'HS256'
    ACCESS_TOKEN_EXPIRE_MINUTES = '15'
    REFRESH_TOKEN_EXPIRE_MINUTES = '10080'
    PROJECT_NAME = 'OXALIA API (CI)'
    ENVIRONMENT = 'test'
    USE_STUB_MODEL = 'true'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out OXALIA repository...'
                checkout scm
            }
        }

        stage('Backend Install') {
            steps {
                dir("${BACKEND_DIR}") {
                    sh '''
                        python3.11 -m venv venv
                        . venv/bin/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt
                    '''
                }
            }
        }

        stage('Backend Lint') {
            steps {
                dir("${BACKEND_DIR}") {
                    sh '''
                        . venv/bin/activate
                        ruff check app tests
                    '''
                }
            }
        }

        stage('Backend Tests') {
            steps {
                dir("${BACKEND_DIR}") {
                    sh '''
                        . venv/bin/activate
                        pytest
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Backend CI pipeline finished.'
        }

        success {
            echo 'Backend CI passed successfully.'
        }

        failure {
            echo 'Backend CI failed. Check Jenkins logs.'
        }
    }
}
