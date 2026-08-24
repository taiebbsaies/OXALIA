pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Repository checked out successfully'
            }
        }

        stage('Backend Info') {
            steps {
                dir('oxalia_back') {
                    sh 'python3 --version || true'
                    sh 'ls'
                }
            }
        }

        stage('Frontend Info') {
            steps {
                dir('oxalia_front') {
                    sh 'ls'
                }
            }
        }
    }
}
