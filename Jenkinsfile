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


        stage('Unit Tests') {
            steps {
                sh '''
                    echo "Running automated unit tests..."
                    python3 -m unittest discover -s tests -v
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

        stage('Package') {
            steps {
                sh '''
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

print("Application package created.")
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
            }
        }
    }

    post {
        success {
            echo 'Application CI pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the failed stage and console output.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
