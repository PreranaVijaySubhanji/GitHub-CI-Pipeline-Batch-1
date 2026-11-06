pipeline {
    agent any

    parameters {
        choice(
            name: 'TARGET_ENV',
            choices: ['dev', 'test'],
            description: 'Select the target environment for this CI run'
        )
    }

    options {
        timestamps()
        skipDefaultCheckout(true)
    }

    environment {
        APP_NAME = 'calculator'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code retrieved from GitHub.'
            }
        }

        stage('Environment Check') {
            steps {
                sh '''
                    echo "Checking Python environment..."
                    python3 --version
                    docker --version
                    echo "Application: $APP_NAME"
                '''
            }
        }

        stage('Run Configuration') {
            steps {
                echo "Selected environment: ${params.TARGET_ENV}"
                echo "Application: ${env.APP_NAME}"
            }
        }

        stage('Credential Handling Demo') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'training-demo-token',
                        variable: 'DEMO_TOKEN'
                    )
                ]) {
                    sh '''
                        if [ -n "$DEMO_TOKEN" ]; then
                            echo "Training credential was loaded."
                        else
                            echo "Training credential is missing."
                            exit 1
                        fi
                    '''
                }
            }
        }

        stage('Prepare Python Tests') {
            steps {
                sh '''
                    echo "Preparing Python test discovery..."

                    mkdir -p app tests
                    touch app/__init__.py
                    touch tests/__init__.py

                    python3 - <<'PY'
from pathlib import Path

test_file = Path("tests/test_calculator.py")

if not test_file.exists():
    raise SystemExit("ERROR: tests/test_calculator.py is missing")

content = test_file.read_text()

content = content.replace(
    'if name == "__main__":',
    'if __name__ == "__main__":'
)

test_file.write_text(content)

print("Python test discovery preparation completed.")
PY
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    echo "Running automated unit tests..."

                    python3 -m unittest discover \
                        -s tests \
                        -t . \
                        -v

                    echo "Unit tests completed successfully."
                '''
            }
        }

        stage('Compile Check') {
            steps {
                sh '''
                    echo "Checking Python source syntax..."

                    python3 -m compileall -q app tests

                    echo "Compile check passed."
                '''
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    env.IMAGE_TAG = "batch1-calculator:${env.BUILD_NUMBER}"
                }

                sh '''
                    echo "Building Docker image..."

                    docker build -t "$IMAGE_TAG" .

                    echo "Docker image build completed."
                '''
            }
        }

        stage('Docker Image Validation') {
            steps {
                sh '''
                    echo "Checking Docker image..."

                    docker image inspect "$IMAGE_TAG" >/dev/null

                    docker images

                    echo "Docker image exists and is readable."
                '''
            }
        }

        stage('Docker Container Smoke Test') {
            steps {
                sh '''
                    echo "Starting calculator container..."

                    docker run --rm "$IMAGE_TAG" > container-output.txt

                    cat container-output.txt

                    grep -q "Calculator container is running" container-output.txt

                    grep -q "10 + 5 = 15" container-output.txt

                    echo "Container smoke test passed."
                '''
            }
        }

        stage('Package') {
            steps {
                sh '''
                    echo "Creating application package..."

                    mkdir -p dist

                    python3 - <<'PY'
import zipfile

files = [
    "app/calculator.py",
    "tests/test_calculator.py"
]

with zipfile.ZipFile(
    "dist/calculator-package.zip",
    "w",
    zipfile.ZIP_DEFLATED
) as package:

    for file in files:
        package.write(file)

print("Application package created successfully.")
PY

                    ls -lh dist/
                '''
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts(
                    artifacts: 'dist/calculator-package.zip',
                    fingerprint: true
                )

                echo 'Application artifact archived successfully.'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x

                        IMAGE_REPO="$DOCKERHUB_USERNAME/batch1-calculator"

                        VERSIONED_IMAGE="$IMAGE_REPO:$BUILD_NUMBER"

                        echo "Logging in to Docker Hub..."

                        trap 'docker logout >/dev/null 2>&1 || true' EXIT

                        echo "$DOCKERHUB_TOKEN" | docker login \
                            --username "$DOCKERHUB_USERNAME" \
                            --password-stdin

                        echo "Tagging Docker image..."

                        docker tag "$IMAGE_TAG" "$VERSIONED_IMAGE"

                        echo "Publishing image to Docker Hub..."

                        docker push "$VERSIONED_IMAGE"

                        echo "Docker image published successfully."
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Application CI pipeline completed successfully.'
            echo 'Docker image published to Docker Hub.'
        }

        failure {
            echo 'FAILURE: Pipeline execution failed.'
            echo 'Check the failed stage in Console Output.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
