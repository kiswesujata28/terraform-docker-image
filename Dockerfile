FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive

# update packages
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y curl binutils gnupg zip

# add sbt repo
#RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list \
# && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add -

# add docker repo
RUN echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" | tee -a /etc/apt/sources.list.d/docker.list \
 && curl -sL "https://download.docker.com/linux/ubuntu/gpg" | apt-key add -

#install build system
RUN apt-get update \
 && apt-get install -y openjdk-11-jdk-headless binutils python3 python3-pip docker-ce-cli

# download terraform
ENV TERRAFORM_VERSION=0.13.4
RUN curl -L -o tmp.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && unzip -d /usr/local/bin tmp.zip \
 && rm tmp.zip \
 && chmod +x /usr/local/bin/terraform

# get build script reqs
RUN pip3 install pip wheel --upgrade

ADD requirements.txt /root/requirements.txt
RUN pip3 install -r /root/requirements.txt