FROM jenkins/jenkins:lts
MAINTAINER Lawrence Mulligan <lmulligan@lpmnet.com>

# Suppress apt installation warnings
ENV DEBIAN_FRONTEND=noninteractive

# Change to root user
USER root

# Used to set the docker group ID
# Set to 497 by default, which is the group ID used by AWS Linux ECS Instance
ARG DOCKER_GID=497

# Create Docker Group with GID
# Set default value of 497 if DOCKER_GID set to blank string by Docker Compose
RUN groupadd -g ${DOCKER_GID:-497} docker

# Used to control Docker and Docker Compose versions installed
# NOTE: As of February 2016, AWS Linux ECS only supports Docker 1.9.1
#ARG DOCKER_ENGINE=1.10.2
#ARG DOCKER_COMPOSE=1.6.2

# Install base packages
RUN apt-get update -y && \
    apt-get install apt-transport-https curl gnupg2 software-properties-common python-dev python-setuptools gcc make libssl-dev -y && \
    easy_install pip

# Install Docker Engine
#RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
#    echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | tee /etc/apt/sources.list.d/docker.list && \
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"  && \
    apt-get update -y && \
    apt-get install docker-ce -y && \
    usermod -aG docker jenkins && \
    usermod -aG users jenkins && \
    usermod -aG staff jenkins

# Install Docker Compose
RUN pip install docker-compose && \
    pip install ansible boto boto3

# Change to jenkins user
USER jenkins

# Add Jenkins plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh  `cat /usr/share/jenkins/ref/plugins.txt` && \
    echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state && \
    echo 2.0 > /usr/share/jenkins/ref/jenkins.install.InstallUtil.lastExecVersion
