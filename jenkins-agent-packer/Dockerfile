FROM jenkins/inbound-agent as agent

FROM alpine:3.12.0

RUN apk -U add openjdk11-jre docker git make wget

# Descargar e instalar Packer
RUN wget https://releases.hashicorp.com/packer/1.8.5/packer_1.8.5_linux_amd64.zip \
    && unzip packer_1.8.5_linux_amd64.zip \
    && mv packer /usr/local/bin/ \
    && rm packer_1.8.5_linux_amd64.zip

COPY --from=agent /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=agent /usr/share/jenkins/agent.jar /usr/share/jenkins/agent.jar

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]
