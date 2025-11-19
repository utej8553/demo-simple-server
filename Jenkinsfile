pipeline {
  agent any

  environment {
    GIT_URL        = "https://github.com/utej8553/demo-simple-server"
    DOCKERHUB_REPO = "utej8553/jenkins-demo"
    CONTAINER_NAME = "jenkins-demo"
    TARGET_PORT_HOST = "80"    
    TARGET_PORT_CONT = "8080"  
  }

  stages {
    stage('Checkout') {
      steps {
        echo "Cloning ${env.GIT_URL}"
        git url: "${env.GIT_URL}", branch: "main"
      }
    }

    stage('Build (Maven)') {
      steps {
        sh "mvn -B clean package"
        sh "ls -la target || true"
      }
    }

    stage('Prepare tag') {
      steps {
        script {
          env.SHORT_COMMIT = sh(script: "git rev-parse --short=7 HEAD", returnStdout: true).trim()
          env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.SHORT_COMMIT}"
          echo "Image tag: ${env.IMAGE_TAG}"
        }
      }
    }

    stage('Build Docker image') {
      steps {
        sh "docker build -t ${DOCKERHUB_REPO}:${IMAGE_TAG} ."
        sh "docker tag ${DOCKERHUB_REPO}:${IMAGE_TAG} ${DOCKERHUB_REPO}:latest"
      }
    }

    stage('Push to Docker Hub (secure)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            set -e
            echo "Logging into Docker Hub as ${DOCKER_USER}"
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}
            docker push ${DOCKERHUB_REPO}:latest
            docker logout
          '''
        }
      }
    }

    stage('Deploy - replace running container') {
      steps {
        sh '''
          set -e
          IMAGE=${DOCKERHUB_REPO}:${IMAGE_TAG}
          NAME=${CONTAINER_NAME}

          # stop & remove
          if docker ps -q --filter "name=$NAME" | grep -q .; then
            docker rm -f $NAME || true
          fi
          if docker ps -aq --filter "name=$NAME" | grep -q .; then
            docker rm -f $NAME || true
          fi

          # run host port 80 -> container 8080
          docker run -d --name $NAME --restart unless-stopped -p ${TARGET_PORT_HOST}:${TARGET_PORT_CONT} $IMAGE

          docker image prune -f || true
        '''
      }
    }
  }

  post {
    success { echo "SUCCESS: ${DOCKERHUB_REPO}:${IMAGE_TAG} pushed and deployed." }
    failure { echo "FAILURE: Check console output." }
  }
}
