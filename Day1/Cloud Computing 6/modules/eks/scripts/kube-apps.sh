#!/bin/bash
set -euo pipefail
exec > >(tee -a /tmp/kube-apps.log) 2>&1

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="gj2026-eks-cluster"
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION_CODE}.amazonaws.com"
MANIFEST="/home/ec2-user/eks/manifest"

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $REGION_CODE

kubectl create ns skills     --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns logging    --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns monitoring --dry-run=client -o yaml | kubectl apply -f -

aws ecr get-login-password --region $REGION_CODE | docker login --username AWS --password-stdin $ECR
mirror() {
  aws ecr create-repository --repository-name "$2" --region $REGION_CODE > /dev/null 2>&1 || true
  docker pull "$1"
  docker tag "$1" "${ECR}/$2:$3"
  docker push "${ECR}/$2:$3"
}

cat > /tmp/pi-trust.json <<JSON
{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow",
  "Principal": { "Service": "pods.eks.amazonaws.com" },
  "Action": ["sts:AssumeRole","sts:TagSession"] } ] }
JSON

BOOK_ROLE="gj2026-book-dynamodb-role"
BOOK_POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/gj2026-book-dynamodb-write"
aws iam create-role --role-name $BOOK_ROLE --assume-role-policy-document file:///tmp/pi-trust.json > /dev/null 2>&1 || true
aws iam attach-role-policy --role-name $BOOK_ROLE --policy-arn $BOOK_POLICY_ARN
kubectl -n skills create serviceaccount book-sa --dry-run=client -o yaml | kubectl apply -f -
aws eks create-pod-identity-association --cluster-name $EKS_CLUSTER_NAME --namespace skills --service-account book-sa --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${BOOK_ROLE} --region $REGION_CODE > /dev/null 2>&1 || true

aws ecr create-repository --repository-name book --region $REGION_CODE > /dev/null 2>&1 || true
docker build -t ${ECR}/book:latest /home/ec2-user/eks/book
docker push ${ECR}/book:latest
aws ecr batch-delete-image --repository-name book --region $REGION_CODE --image-ids imageTag=v1.0.1 > /dev/null 2>&1 || true
sed "s|IMAGE_PLACEHOLDER|${ECR}/book:latest|g" $MANIFEST/book/deployment.yaml | kubectl apply -f -
kubectl apply -f $MANIFEST/book/service.yaml

LBC_ROLE="gj2026-alb-controller-role"
curl -fsSL -o /tmp/alb-iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.0/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file:///tmp/alb-iam-policy.json > /dev/null 2>&1 || true
aws iam create-role --role-name $LBC_ROLE --assume-role-policy-document file:///tmp/pi-trust.json > /dev/null 2>&1 || true
aws iam attach-role-policy --role-name $LBC_ROLE --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy
kubectl -n kube-system create serviceaccount aws-load-balancer-controller --dry-run=client -o yaml | kubectl apply -f -
aws eks create-pod-identity-association --cluster-name $EKS_CLUSTER_NAME --namespace kube-system --service-account aws-load-balancer-controller --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${LBC_ROLE} --region $REGION_CODE > /dev/null 2>&1 || true
mirror public.ecr.aws/eks/aws-load-balancer-controller:v2.13.0 eks/aws-load-balancer-controller v2.13.0
helm repo add eks https://aws.github.io/eks-charts
helm repo update
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=gj2026-vpc" --query "Vpcs[].VpcId" --output text --region $REGION_CODE)
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$REGION_CODE \
  --set vpcId=$VPC_ID \
  --set image.repository=${ECR}/eks/aws-load-balancer-controller \
  --set image.tag=v2.13.0 \
  --set nodeSelector.role=addon
kubectl -n kube-system rollout status deploy/aws-load-balancer-controller --timeout=180s
kubectl apply -f $MANIFEST/book/ingress.yaml

FB_ROLE="gj2026-fluentbit-role"
aws iam create-role --role-name $FB_ROLE --assume-role-policy-document file:///tmp/pi-trust.json > /dev/null 2>&1 || true
aws iam attach-role-policy --role-name $FB_ROLE --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
kubectl -n logging create serviceaccount aws-for-fluent-bit --dry-run=client -o yaml | kubectl apply -f -
aws eks create-pod-identity-association --cluster-name $EKS_CLUSTER_NAME --namespace logging --service-account aws-for-fluent-bit --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${FB_ROLE} --region $REGION_CODE > /dev/null 2>&1 || true
mirror public.ecr.aws/aws-observability/aws-for-fluent-bit:2.32.5 aws-observability/aws-for-fluent-bit 2.32.5
kubectl -n logging create configmap fluentbit-setaz \
  --from-file=setaz.lua=$MANIFEST/fluent-bit/setaz.lua \
  --dry-run=client -o yaml | kubectl apply -f -
helm upgrade -i aws-for-fluent-bit eks/aws-for-fluent-bit \
  -n logging \
  -f $MANIFEST/fluent-bit/values.yaml \
  --set image.repository=${ECR}/aws-observability/aws-for-fluent-bit \
  --set image.tag=2.32.5 || true

mirror quay.io/prometheus/prometheus:v2.54.1 prometheus v2.54.1
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade -i prometheus prometheus-community/prometheus \
  -n monitoring \
  -f $MANIFEST/prometheus/values.yaml \
  --set server.image.repository=${ECR}/prometheus \
  --set server.image.tag=v2.54.1 || true

GF_ROLE="gj2026-grafana-role"
aws iam create-role --role-name $GF_ROLE --assume-role-policy-document file:///tmp/pi-trust.json > /dev/null 2>&1 || true
aws iam attach-role-policy --role-name $GF_ROLE --policy-arn arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess
kubectl -n monitoring create serviceaccount grafana --dry-run=client -o yaml | kubectl apply -f -
aws eks create-pod-identity-association --cluster-name $EKS_CLUSTER_NAME --namespace monitoring --service-account grafana --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${GF_ROLE} --region $REGION_CODE > /dev/null 2>&1 || true
kubectl apply -f $MANIFEST/grafana/configmap.yaml
mirror docker.io/grafana/grafana:11.3.0 grafana/grafana 11.3.0
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade -i grafana grafana/grafana \
  -n monitoring \
  -f $MANIFEST/grafana/values.yaml \
  --set global.imageRegistry=${ECR} \
  --set image.registry=${ECR} \
  --set image.repository=grafana/grafana \
  --set image.tag=11.3.0 || true
kubectl apply -f $MANIFEST/grafana/ingress.yaml

sed "s|IMAGE_PLACEHOLDER|${ECR}/ecr-public/nginx/nginx:latest|g" \
  $MANIFEST/nginx-preload/daemonset.yaml | kubectl apply -f -

kubectl get csr -o go-template='{{range .items}}{{if not .status.conditions}}{{if eq .spec.signerName "kubernetes.io/kubelet-serving"}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}{{end}}' 2>/dev/null \
  | xargs -r -n1 kubectl certificate approve 2>/dev/null || true

sed "s|KUBECTL_IMAGE|${ECR}/ecr-public/bitnami/kubectl:latest|g" \
  $MANIFEST/csr-approver/cronjob.yaml | kubectl apply -f -
