#!/bin/bash
REGION_CODE="ap-northeast-2"

dnf install --allowerasing -y jq curl wget unzip vim dos2unix mariadb105
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

dnf install -y docker
systemctl start docker
systemctl enable --now docker
usermod -aG docker ec2-user
chmod 666 /var/run/docker.sock

sed -i 's|PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl restart sshd
echo 'Skill53##' | passwd --stdin ec2-user
echo 'Skill53##' | passwd --stdin root

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.35.2/2026-02-27/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -rf get_helm.sh

K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
curl -fsSLO https://github.com/derailed/k9s/releases/download/$${K9S_VERSION}/k9s_Linux_amd64.tar.gz
sudo tar -C /usr/local/bin -xf k9s_Linux_amd64.tar.gz
chmod +x /usr/local/bin/k9s

mkdir -p /home/ec2-user/app/user /home/ec2-user/app/product /home/ec2-user/app/stress /home/ec2-user/kubernetes

aws s3 cp s3://${src_bucket}/ /home/ec2-user/ --recursive --region $REGION_CODE

chown -R ec2-user:ec2-user /home/ec2-user/
chmod +x /home/ec2-user/scripts/*
dos2unix /home/ec2-user/scripts/*

/home/ec2-user/scripts/kube-setup.sh
