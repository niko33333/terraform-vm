#!/bin/bash
apt-get update -y && apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y && apt-get install -y docker-ce docker-ce-cli containerd.io
apt install -y awscli
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${docker_image}
docker pull ${docker_image}
sudo docker run -d -p 80:80 ${docker_image}