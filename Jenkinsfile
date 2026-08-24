pipeline {
    agent any

    environment {
        BACKEND_DIR = 'oxalia_back'
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
                        python3 -m venv venv
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
