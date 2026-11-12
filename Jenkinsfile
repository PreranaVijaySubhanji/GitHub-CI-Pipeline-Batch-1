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

        stage('Push Docker Image to AWS ECR') {
            steps {
                sh '''
                    set -eu

                    echo "Checking AWS CLI..."
                    aws --version

                    echo "Checking AWS identity..."
                    aws sts get-caller-identity

                    AWS_REGION="ap-southeast-1"

                    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                        --query Account \
                        --output text)

                    ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                    ECR_REPOSITORY="batch1-calculator"

                    ECR_IMAGE="${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"

                    echo "AWS account: ${AWS_ACCOUNT_ID}"
                    echo "AWS region: ${AWS_REGION}"
                    echo "ECR repository: ${ECR_REPOSITORY}"
                    echo "Image tag: ${BUILD_NUMBER}"

                    echo "Authenticating Docker with Amazon ECR..."

                    aws ecr get-login-password \
                        --region "$AWS_REGION" | \
                        docker login \
                            --username AWS \
                            --password-stdin "$ECR_REGISTRY"

                    echo "Tagging the existing Docker image..."

                    docker tag "$IMAGE_TAG" "$ECR_IMAGE"

                    echo "Pushing Docker image to Amazon ECR..."

                    docker push "$ECR_IMAGE"

                    echo "Verifying the image in ECR..."

                    aws ecr describe-images \
                        --repository-name "$ECR_REPOSITORY" \
                        --image-ids imageTag="$BUILD_NUMBER" \
                        --region "$AWS_REGION"

                    echo "Image successfully published and verified in ECR."

                    docker logout "$ECR_REGISTRY" || true
                '''
            }
        }
