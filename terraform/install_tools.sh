#!/bin/bash

set -euxo pipefail

# Update system
apt-get update -y
apt-get upgrade -y

# Install Java and required packages
apt-get install -y \
    fontconfig \
    openjdk-21-jre \
    wget \
    curl \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https

# -------------------------
# Jenkins
# -------------------------

mkdir -p /etc/apt/keyrings

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list

apt-get update -y
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# -------------------------
# Docker
# -------------------------

apt-get install -y docker.io

systemctl enable docker
systemctl start docker

usermod -aG docker jenkins

# Restart Jenkins so it picks up Docker group
systemctl restart jenkins

# -------------------------
# Trivy
# -------------------------

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | gpg --dearmor \
    > /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb \
$(lsb_release -sc) main" \
    > /etc/apt/sources.list.d/trivy.list

apt-get update -y
apt-get install -y trivy

# -------------------------
# AWS CLI
# -------------------------

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o /tmp/awscliv2.zip

apt-get install -y unzip

unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# -------------------------
# kubectl
# -------------------------

curl -LO "https://dl.k8s.io/release/$(curl -L -s \
    https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# -------------------------
# Helm
# -------------------------

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    | bash

# -------------------------
# Verification
# -------------------------

java -version
jenkins --version
docker --version
aws --version
kubectl version --client
helm version
trivy --version