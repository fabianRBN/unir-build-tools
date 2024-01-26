JENKINS_DOCKER_AGENT_SECRET := 48f8b8b019cda9cf6f72412aa10b0c738999f4d2a6b972c2c19448802ac80159 
JENKINS_MAVEN_AGENT_SECRET := a183f9497387220913377e58952a18dd678479e6b45234e733d7c28cda988e68 
JENKINS_NODE_AGENT_SECRET := 4702f9a12ce51d2ef1dba704de74caaa8a3c56f2ba29aea33b6b653d000455eb
JENKINS_TERRAFORM_AGENT_SECRET := 1c06c41e5367ca0e09e81fefd28711c00f89c5c1cfb598a8597194feb48fd7b4  
JENKINS_PACKER_AGENT_SECRET := 05997547ed894d945c9381a6444e2ef59a313a0b092d48e945165755656a66fb  
GITLAB_TOKEN := 1Lrw11yzWRrsaiZLxwci

.PHONY: all $(MAKECMDGOALS)

build-agents:
	docker build -t jenkins-agent-docker ./jenkins-agent-docker
	docker build -t jenkins-agent-maven ./jenkins-agent-maven
	docker build -t jenkins-agent-node ./jenkins-agent-node
	docker build -t jenkins-agent-terraform ./jenkins-agent-terraform
	docker build -t jenkins-agent-packer ./jenkins-agent-packer

start-simple-jenkins:
	docker run -d --rm --stop-timeout 60 --name jenkins-server --volume jenkins-data:/var/jenkins_home -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts

start-jenkins:
	docker network create jenkins || true
	docker run -d --rm --stop-timeout 60 --network jenkins --name jenkins-docker --privileged --network-alias docker  --env DOCKER_TLS_CERTDIR=/certs  --volume jenkins-docker-certs:/certs/client  --volume jenkins-data:/var/jenkins_home -p 2376:2376 -p 80:80 docker:dind
	docker run -d --rm --stop-timeout 60 --network jenkins --name jenkins-server --env DOCKER_HOST=tcp://docker:2376 --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 --volume jenkins-data:/var/jenkins_home --volume jenkins-docker-certs:/certs/client:ro -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts
	sleep 30
	docker run -d --rm --network jenkins --name jenkins-agent-docker --init --env DOCKER_HOST=tcp://docker:2376 --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 --volume jenkins-docker-certs:/certs/client:ro --env JENKINS_URL=http://jenkins-server:8080 --env JENKINS_AGENT_NAME=agent01 --env JENKINS_SECRET=$(JENKINS_DOCKER_AGENT_SECRET) --env JENKINS_AGENT_WORKDIR=/home/jenkins/agent jenkins-agent-docker
	docker run -d --rm --network jenkins --name jenkins-agent-maven --init --env JENKINS_URL=http://jenkins-server:8080 --env JENKINS_AGENT_NAME=agent02 --env JENKINS_SECRET=$(JENKINS_MAVEN_AGENT_SECRET) --env JENKINS_AGENT_WORKDIR=/home/jenkins/agent jenkins-agent-maven
	docker run -d --rm --network jenkins --name jenkins-agent-node --init --env JENKINS_URL=http://jenkins-server:8080 --env JENKINS_AGENT_NAME=agent03 --env JENKINS_SECRET=$(JENKINS_NODE_AGENT_SECRET) --env JENKINS_AGENT_WORKDIR=/home/jenkins/agent jenkins-agent-node
	docker run -d --rm --network jenkins --name jenkins-agent-terraform --init --env JENKINS_URL=http://jenkins-server:8080 --env JENKINS_AGENT_NAME=agent04 --env JENKINS_SECRET=$(JENKINS_TERRAFORM_AGENT_SECRET) --env JENKINS_AGENT_WORKDIR=/home/jenkins/agent jenkins-agent-terraform
	docker run -d --rm --network jenkins --name jenkins-agent-packer --init --env JENKINS_URL=http://jenkins-server:8080 --env JENKINS_AGENT_NAME=agent05 --env JENKINS_SECRET=$(JENKINS_PACKER_AGENT_SECRET) --env JENKINS_AGENT_WORKDIR=/home/jenkins/agent jenkins-agent-packer


jenkins-password:
	docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword && echo "fabian95"

stop-jenkins:
	docker stop jenkins-agent-docker || true
	docker stop jenkins-agent-terraform || true
	docker stop jenkins-agent-packer || true
	docker stop jenkins-agent-maven || true
	docker stop jenkins-agent-node || true
	docker stop jenkins-docker || true
	docker stop jenkins-server || true
	docker network rm jenkins || true


start-gitlab:
	docker network create gitlab || true
	docker run -d --rm --stop-timeout 60 --network gitlab --hostname localhost --name gitlab-server -p 80:80 -p 443:443 -p 2222:22 --volume gitlab_config:/etc/gitlab --volume gitlab_logs:/var/log/gitlab --volume gitlab_data:/var/opt/gitlab gitlab/gitlab-ce:latest
	sleep 90
	docker run -d --rm --network gitlab --name gitlab-runner --volume gitlab-runner-config:/etc/gitlab-runner gitlab/gitlab-runner
	docker run --rm --network gitlab --volume gitlab-runner-config:/etc/gitlab-runner gitlab/gitlab-runner register --non-interactive --executor "shell" --url "http://gitlab-server/" --registration-token "$(GITLAB_TOKEN)" --description "runner01" --tag-list "ssh" --locked="false" --access-level="not_protected"

stop-gitlab:
	docker stop gitlab-server || true
	docker stop gitlab-runner || true
	docker network rm gitlab || true

start-nexus:
	docker run -d --name nexus-server -v nexus-data:/nexus-data -p 8081:8081 sonatype/nexus3

start-nexus-jenkins:
	docker run -d --rm --network jenkins --name nexus-server -v nexus-data:/nexus-data -p 8081:8081 sonatype/nexus3

nexus-password:
	docker exec nexus-server cat /nexus-data/admin.password && echo ""

stop-nexus:
	docker stop --time=120 nexus-server
