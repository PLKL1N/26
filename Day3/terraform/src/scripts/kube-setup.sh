#!/bin/bash

REGION_CODE="ap-northeast-2"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=apdev-vpc" --query 'Vpcs[0].VpcId' --output text --region $REGION_CODE)

EKS_CLUSTER_NAME="apdev-eks-cluster"
PUBLIC_A_SN_NAME="apdev-pub-sn-a"
PUBLIC_B_SN_NAME="apdev-pub-sn-b"
PUBLIC_C_SN_NAME="apdev-pub-sn-c"
PRIVATE_A_SN_NAME="apdev-priv-sn-a"
PRIVATE_B_SN_NAME="apdev-priv-sn-b"
PRIVATE_C_SN_NAME="apdev-priv-sn-c"

PUBLIC_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PUBLIC_B_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_B_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PUBLIC_C_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_C_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_B_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_B_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_C_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_C_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)

CLUSTER_YAML_PATH=$(sudo find / -name "cluster.yaml" 2> /dev/null)

sed -i "s|VPC_ID|$VPC_ID|g" $CLUSTER_YAML_PATH
sed -i "s|ACCOUNT_ID|$ACCOUNT_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PUBLIC_A|$PUBLIC_A_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PUBLIC_B|$PUBLIC_B_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PUBLIC_C|$PUBLIC_C_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PRIVATE_A|$PRIVATE_A_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PRIVATE_B|$PRIVATE_B_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PRIVATE_C|$PRIVATE_C_SN_ID|g" $CLUSTER_YAML_PATH

PUBLIC_SN_IDS=("$PUBLIC_A_SN_ID" "$PUBLIC_B_SN_ID" "$PUBLIC_C_SN_ID")
PRIVATE_SN_IDS=("$PRIVATE_A_SN_ID" "$PRIVATE_B_SN_ID" "$PRIVATE_C_SN_ID")
for name in "${PUBLIC_SN_IDS[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/cluster/$EKS_CLUSTER_NAME,Value=shared
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/elb,Value=1
done
for name in "${PRIVATE_SN_IDS[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/cluster/$EKS_CLUSTER_NAME,Value=shared
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/internal-elb,Value=1
done

eksctl create cluster -f $CLUSTER_YAML_PATH
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $REGION_CODE
sudo -u ec2-user aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $REGION_CODE
kubectl create ns apdev

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

eksctl create iamserviceaccount \
  --cluster $EKS_CLUSTER_NAME \
  --namespace apdev \
  --name product \
  --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/apdev-product-s3-access \
  --approve

SECRET_NAME=$(aws secretsmanager list-secrets --query "SecretList[?Name=='rds-secret'].Name" --output text --region $REGION_CODE)
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE)
DB_USER=$(echo $SECRET_JSON | jq -r ".username")
DB_PASSWORD=$(echo $SECRET_JSON | jq -r ".password")
DB_HOST=$(echo $SECRET_JSON | jq -r ".host")
DB_PORT=$(echo $SECRET_JSON | jq -r ".port")
DB_NAME=$(echo $SECRET_JSON | jq -r ".dbname")
S3_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'apdev-images')].Name" --output text)

K8S_DIR="/home/ec2-user/kubernetes"

sed -i "s|ACCOUNT_ID|$ACCOUNT_ID|g" $K8S_DIR/*.yaml
sed -i "s|DB_USER|$DB_USER|g" $K8S_DIR/*.yaml
sed -i "s|DB_PASSWORD|$DB_PASSWORD|g" $K8S_DIR/*.yaml
sed -i "s|DB_HOST|$DB_HOST|g" $K8S_DIR/*.yaml
sed -i "s|DB_PORT|$DB_PORT|g" $K8S_DIR/*.yaml
sed -i "s|DB_NAME|$DB_NAME|g" $K8S_DIR/*.yaml
sed -i "s|S3_BUCKET_NAME|$S3_BUCKET_NAME|g" $K8S_DIR/*.yaml

chown -R ec2-user:ec2-user $K8S_DIR

kubectl apply -f $K8S_DIR/0-config.yaml
