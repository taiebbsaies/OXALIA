pipeline {
    agent any

    environment {
        BACKEND_DIR = 'oxalia_back'
        DATABASE_URL = 'postgresql+asyncpg://postgres:postgres@db:5432/oxalia'
        JWT_SECRET_KEY = 'ci-test-secret-key-32-bytes-minimum!!'
        JWT_ALGORITHM = 'HS256'
        ACCESS_TOKEN_EXPIRE_MINUTES = '15'
        REFRESH_TOKEN_EXPIRE_MINUTES = '10080'
        PROJECT_NAME = 'OXALIA API (CI)'
        ENVIRONMENT = 'test'
        USE_STUB_MODEL = 'true'
        SONAR_HOST_URL = "${env.SONAR_HOST_URL ?: 'http://sonarqube:9000'}"
        SONAR_PROJECT_KEY = 'oxalia_back'
    }

    stages {
        stage('Checkout') {
            steps {
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
                        pip install -r requirements.txt pytest-cov
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
                        ruff format --check app tests
                    '''
                }
            }
        }

        stage('Backend Tests') {
            steps {
                dir("${BACKEND_DIR}") {
                    sh '''
                        . venv/bin/activate
                        pytest --cov=app --cov-report=xml:coverage.xml --cov-report=term
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                dir("${BACKEND_DIR}") {
                    sh '''
                        set -e
                        if [ -z "$SONAR_TOKEN" ]; then
                          echo "SONAR_TOKEN is empty."
                          echo "Open http://localhost:9000, generate a token,"
                          echo "set SONAR_TOKEN in oxalia_back/.env, then recreate Jenkins."
                          exit 1
                        fi
                        if ! command -v sonar-scanner >/dev/null 2>&1; then
                          echo "sonar-scanner is not on PATH. Rebuild the Jenkins image:"
                          echo "docker compose -f docker-compose.yml -f docker-compose.ci.yml up -d --build jenkins"
                          exit 1
                        fi
                        set +x
                        sonar-scanner \
                          -Dsonar.host.url="$SONAR_HOST_URL" \
                          -Dsonar.token="$SONAR_TOKEN"
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                sh '''
                    set -e
                    set +x
                    STATUS=""
                    for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
                      STATUS=$(curl -sf -u "${SONAR_TOKEN}:" \
                        "${SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=${SONAR_PROJECT_KEY}" \
                        | python3 -c "import sys,json; print(json.load(sys.stdin)['projectStatus']['status'])")
                      echo "Quality Gate attempt $i: $STATUS"
                      if [ "$STATUS" = "OK" ] || [ "$STATUS" = "ERROR" ] || [ "$STATUS" = "WARN" ]; then
                        break
                      fi
                      sleep 5
                    done
                    if [ "$STATUS" != "OK" ] && [ "$STATUS" != "WARN" ]; then
                      echo "SonarQube Quality Gate failed: $STATUS"
                      exit 1
                    fi
                '''
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
