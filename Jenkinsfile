#!groovy

node {
    checkout scm

    def dockerRepoName = 'zooniverse/interventions-gateway'
    def dockerImageName = "${dockerRepoName}:${BRANCH_NAME}"
    def newImage = null

    stage('Build Docker image') {
        newImage = docker.build(dockerImageName)
        newImage.push()
    }

     if (BRANCH_NAME == 'master') {
         stage('Update latest tag') {
             newImage.push('latest')
         }

         stage('Deploy to Swarm') {
             sh """
                 cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
                 ./hermes_wrapper.sh exec swarm19a -- \
                     docker stack deploy --prune \
                     -c /opt/infrastructure/stacks/interventions-gateway-staging.yml \
                     interventions-gateway-staging
             """
         }
     }

     if (BRANCH_NAME == 'production') {
         stage('Update production tag') {
             newImage.push('production')
         }

         stage('Deploy to Swarm') {
             sh """
                 cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
                 ./hermes_wrapper.sh exec swarm19a -- \
                     docker stack deploy --prune \
                     -c /opt/infrastructure/stacks/interventions-gateway.yml \
                     interventions-gateway
             """
         }
     }
}
