
pipeline {
    agent any

    options {
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Source repository is configured in Jenkins.'
            }
        }

        stage('Validate Source') {
            steps {
                sh '''
                    echo "Checking required project files..."
                    test -f README.md
                    test -f Jenkinsfile
                    echo "Validation successful."
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                    mkdir -p build
                    echo "Jenkins CI Pipeline - Batch 1" > build/build-info.txt
                    echo "Build artifact created."
                    cat build/build-info.txt
                '''
            }
        }

        stage('Archive Artifact') {
            steps {
                archiveArtifacts artifacts: 'build/build-info.txt',
                                 fingerprint: true
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Review the console output.'
        }
        always {
            echo 'Pipeline execution has finished.'
        }
    }
}
