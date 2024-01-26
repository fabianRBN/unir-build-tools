# Usar jenkins/inbound-agent como base para la imagen
FROM jenkins/inbound-agent as agent

# Usar alpine:3.12.0 como la imagen base
FROM alpine:3.12.0

# Instalar openjdk11-jre, docker, git, make y wget
RUN apk -U add openjdk11-jre docker git make wget curl unzip

# Descargar e instalar Terraform
RUN wget https://releases.hashicorp.com/terraform/1.0.0/terraform_1.0.0_linux_amd64.zip \
    && unzip terraform_1.0.0_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_1.0.0_linux_amd64.zip

# Instalar Infracost
RUN curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh


# Copiar el agente Jenkins y el archivo jar desde la imagen base
COPY --from=agent /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=agent /usr/share/jenkins/agent.jar /usr/share/jenkins/agent.jar

# Establecer el punto de entrada
ENTRYPOINT ["/usr/local/bin/jenkins-agent"]