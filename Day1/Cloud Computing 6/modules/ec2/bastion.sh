#!/bin/bash
dnf update -y
dnf upgrade -y
dnf install --allowerasing -y jq curl wget unzip vim
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sed -i 's|PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl restart sshd
echo 'worldpay2026!' | passwd --stdin ec2-user
echo 'worldpay2026!' | passwd --stdin root

dnf install -y docker 
systemctl start docker
systemctl enable --now docker
usermod -aG docker ec2-user
chmod 666 /var/run/docker.sock

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.35.2/2026-02-27/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
rm -rf get_helm.sh

mkdir k9s && cd k9s/
curl -LO https://github.com/derailed/k9s/releases/download/v0.50.18/k9s_Linux_amd64.tar.gz
tar -xf k9s_Linux_amd64.tar.gz
chmod +x k9s
sudo mv k9s /usr/local/bin
cd ..
rm -rf k9s