#!/bin/bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="unicorn-eks-cluster"
ALB_SECURITY_GROUP_NAME="unicorn-alb-sg"
FLUENT_BIT_ROLE_NAME="unicorn-fluent-bit-role"
DYNAMODB_ROLE_NAME="unicorn-book-app-role"
LAMBDA_ROLE_NAME="unicorn-get-booking-func-role"

command -v dos2unix >/dev/null 2>&1 && \
  find /home/ec2-user/eks -type f \( -name '*.yaml' -o -name '*.yml' \) -exec dos2unix -q {} +

CLUSTER_YAML_PATH=$(sudo find / -name "cluster.yaml" 2>/dev/null | head -n 1)
FLUENT_BIT_ROLE_ARN=$(aws iam get-role --role-name $FLUENT_BIT_ROLE_NAME --query "Role.Arn" --output text --region $REGION_CODE)
DYNAMODB_ROLE_ARN=$(aws iam get-role --role-name $DYNAMODB_ROLE_NAME --query "Role.Arn" --output text --region $REGION_CODE)
LAMBDA_ROLE_ARN=$(aws iam get-role --role-name $LAMBDA_ROLE_NAME --query "Role.Arn" --output text --region $REGION_CODE)

eksctl create cluster -f $CLUSTER_YAML_PATH
aws eks --region $REGION_CODE update-kubeconfig --name $EKS_CLUSTER_NAME
su - ec2-user -c 'REGION_CODE="ap-northeast-2"; EKS_CLUSTER_NAME="unicorn-eks-cluster"; aws eks --region $REGION_CODE update-kubeconfig --name $EKS_CLUSTER_NAME'

aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$ACCOUNT_ID:root --region $REGION_CODE > /dev/null
aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$ACCOUNT_ID:root --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster --region $REGION_CODE > /dev/null

kubectl create ns unicorn
kubectl create ns logging

eksctl create addon --cluster $EKS_CLUSTER_NAME --name=eks-pod-identity-agent --region $REGION_CODE --force --wait
kubectl rollout status ds/eks-pod-identity-agent -n kube-system --timeout=300s

KMS_PLATFORM_ARN=$(aws kms describe-key --key-id "alias/unicorn-kms-platform" --query "KeyMetadata.Arn" --output text --region $REGION_CODE)
KMS_DATA_ARN=$(aws kms describe-key --key-id "alias/unicorn-kms-data" --query "KeyMetadata.Arn" --output text --region $REGION_CODE)

aws iam put-role-policy --role-name $LAMBDA_ROLE_NAME --policy-name AllowKMSDecrypt \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"kms:Decrypt\",\"Resource\":[\"${KMS_PLATFORM_ARN}\",\"${KMS_DATA_ARN}\"]}]}"
aws iam put-role-policy --role-name $DYNAMODB_ROLE_NAME --policy-name AllowKMSDecrypt \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"kms:Decrypt\",\"Resource\":[\"${KMS_DATA_ARN}\"]}]}"

eksctl create podidentityassociation \
  --region $REGION_CODE \
  --cluster $EKS_CLUSTER_NAME \
  --namespace "logging" \
  --service-account-name "unicorn-fluent-bit-sa" \
  --role-arn $FLUENT_BIT_ROLE_ARN \
  --create-service-account

eksctl create podidentityassociation \
  --region $REGION_CODE \
  --cluster $EKS_CLUSTER_NAME \
  --namespace "unicorn" \
  --service-account-name "unicorn-book-app-sa" \
  --role-arn $DYNAMODB_ROLE_ARN \
  --create-service-account

for i in $(seq 1 30); do
  CNT=$(aws eks list-pod-identity-associations --cluster-name $EKS_CLUSTER_NAME --region $REGION_CODE \
        --query "length(associations[])" --output text 2>/dev/null)
  [ "$CNT" != "None" ] && [ "${CNT:-0}" -ge 2 ] && break
  sleep 5
done

kubectl apply -f /home/ec2-user/eks/manifest/logging/configmap.yaml
kubectl apply -f /home/ec2-user/eks/manifest/logging/daemonset.yaml

kubectl apply -f /home/ec2-user/eks/manifest/configmap.yaml
kubectl apply -f /home/ec2-user/eks/manifest/deployment.yaml
kubectl apply -f /home/ec2-user/eks/manifest/service.yaml

kubectl rollout status ds/fluent-bit -n logging --timeout=300s
kubectl rollout status deploy/unicorn-book-app-deploy -n unicorn --timeout=600s

if ! kubectl exec -n logging ds/fluent-bit -- env 2>/dev/null | grep -q AWS_CONTAINER_CREDENTIALS_FULL_URI; then
  echo "[WARN] pod identity not injected into fluent-bit, restarting..."
  kubectl rollout restart ds/fluent-bit -n logging
  kubectl rollout status ds/fluent-bit -n logging --timeout=300s
fi

helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$EKS_CLUSTER_NAME \
  -f /home/ec2-user/eks/manifest/ingress/values.yaml

ALB_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='$ALB_SECURITY_GROUP_NAME'].GroupId" --output text --region $REGION_CODE)
EKS_CLUSTER_SECURITY_GROUP_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text --region $REGION_CODE)
aws ec2 authorize-security-group-ingress --group-id $EKS_CLUSTER_SECURITY_GROUP_ID --protocol tcp --port 8080 --source-group $ALB_SECURITY_GROUP_ID > /dev/null

sed -i "s|SECURITY_GROUP_ID|$ALB_SECURITY_GROUP_ID|g" /home/ec2-user/eks/manifest/ingress/ingress.yaml

kubectl rollout status deploy/aws-load-balancer-controller -n kube-system --timeout=300s
sleep 15

kubectl apply -f /home/ec2-user/eks/manifest/ingress/ingress.yaml

kubectl create ns monitoring

eksctl utils associate-iam-oidc-provider --region $REGION_CODE --cluster $EKS_CLUSTER_NAME --approve

eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --region $REGION_CODE \
  --cluster $EKS_CLUSTER_NAME \
  --namespace kube-system \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --role-only \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2 \
  --approve

eksctl create addon \
  --name aws-ebs-csi-driver \
  --region $REGION_CODE \
  --cluster $EKS_CLUSTER_NAME \
  --service-account-role-arn arn:aws:iam::$ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole \
  --force \
  --wait

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade -i prometheus prometheus-community/prometheus \
  -n monitoring \
  -f /home/ec2-user/eks/manifest/prometheus/values.yaml

sleep 30

kubectl apply -f /home/ec2-user/eks/manifest/grafana/configmap.yaml

helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo update
helm upgrade -i grafana grafana-community/grafana \
  -n monitoring \
  -f /home/ec2-user/eks/manifest/grafana/values.yaml

kubectl apply -f /home/ec2-user/eks/manifest/grafana/ingress.yaml

kubectl run unicorn-warmup -n unicorn --rm -i --restart=Never \
  --image=curlimages/curl:latest --command -- \
  sh -c 'for i in 1 2 3; do curl -s -o /dev/null -X POST http://unicorn-book-app-svc:8080/v1/book -H "Content-Type: application/json" -d "{\"client_id\":\"C-WARM\",\"username\":\"warm\",\"email\":\"warm@skills.kr\",\"concert_name\":\"Warmup\"}"; sleep 2; done' 2>/dev/null

sleep 30
aws logs describe-log-streams --log-group-name /unicorn/eks/book-app \
  --query "logStreams[].logStreamName" --output text --region $REGION_CODE