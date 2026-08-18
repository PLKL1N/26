#!/bin/bash
set -o pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="skm-eks-cluster"
SQS_NAME="skm-order-queue"
APP_NAMESPACE="skillsmkt"
KEDA_NAMESPACE="keda"
KARPENTER_NAMESPACE="kube-system"
KARPENTER_VERSION="1.12.1"
KARPENTER_NODE_ROLE_NAME="skm-karpenter-node-role"
ADDON_TAINT_KEY="dedicated"
ADDON_TAINT_VALUE="cluster-addon"

SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name $SQS_NAME --query "QueueUrl" --output text --region $REGION_CODE)
CLUSTER_YAML_PATH=$(sudo find / -name "cluster.yaml" 2>/dev/null)

die() { echo "[FATAL] $*" >&2; exit 1; }

cleanup_stale_karpenter_instance_profile() {
  for P in $(aws iam list-instance-profiles-for-role --role-name "$KARPENTER_NODE_ROLE_NAME" \
               --query 'InstanceProfiles[].InstanceProfileName' --output text 2>/dev/null); do
    aws iam remove-role-from-instance-profile --instance-profile-name "$P" --role-name "$KARPENTER_NODE_ROLE_NAME"
    aws iam delete-instance-profile --instance-profile-name "$P"
  done
}

cleanup_stale_karpenter_instance_profile

eksctl create cluster -f $CLUSTER_YAML_PATH || die "eksctl create cluster 실패"

aws eks --region $REGION_CODE update-kubeconfig --name $EKS_CLUSTER_NAME || die "update-kubeconfig 실패"
su - ec2-user -c "aws eks --region $REGION_CODE update-kubeconfig --name $EKS_CLUSTER_NAME"

aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$ACCOUNT_ID:user/wsc-user --region $REGION_CODE > /dev/null 2>&1 || true
aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$ACCOUNT_ID:user/wsc-user --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster --region $REGION_CODE > /dev/null 2>&1 || true

aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$ACCOUNT_ID:role/$KARPENTER_NODE_ROLE_NAME --type EC2_LINUX --region $REGION_CODE > /dev/null 2>&1 \
  || eksctl create iamidentitymapping --cluster $EKS_CLUSTER_NAME --region $REGION_CODE --arn arn:aws:iam::$ACCOUNT_ID:role/$KARPENTER_NODE_ROLE_NAME --group system:bootstrappers --group system:nodes --username system:node:{{EC2PrivateDNSName}} > /dev/null 2>&1 || true

kubectl -n kube-system patch deployment coredns --type merge \
  -p "{\"spec\":{\"template\":{\"spec\":{\"tolerations\":[{\"key\":\"$ADDON_TAINT_KEY\",\"operator\":\"Equal\",\"value\":\"$ADDON_TAINT_VALUE\",\"effect\":\"NoSchedule\"},{\"key\":\"CriticalAddonsOnly\",\"operator\":\"Exists\"},{\"key\":\"node-role.kubernetes.io/control-plane\",\"operator\":\"Exists\",\"effect\":\"NoSchedule\"}]}}}}" || true

kubectl create ns $APP_NAMESPACE || true
kubectl create ns $KEDA_NAMESPACE || true

/home/ec2-user/scripts/karpenter-tag.sh || die "karpenter-tag.sh 실패"

cat << JSON > /tmp/sqs-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SQSAccess",
            "Effect": "Allow",
            "Action": [
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "sqs:ListQueues",
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:ChangeMessageVisibility"
            ],
            "Resource": "*"
        }
    ]
}
JSON

cat << JSON > /tmp/karpenter-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Compute",
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "ssm:GetParameter",
                "pricing:GetProducts",
                "eks:DescribeCluster",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "sqs:ReceiveMessage"
            ],
            "Resource": "*"
        },
        {
            "Sid": "InstanceProfile",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "iam:GetRole",
                "iam:GetInstanceProfile",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:TagInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:ListInstanceProfiles",
                "iam:ListInstanceProfilesForRole"
            ],
            "Resource": "*"
        }
    ]
}
JSON

aws iam create-policy --policy-name SKMSQSPolicy --policy-document file:///tmp/sqs-policy.json > /dev/null 2>&1 || true
aws iam create-policy --policy-name SKMKarpenterControllerPolicy --policy-document file:///tmp/karpenter-policy.json > /dev/null 2>&1 || true

rm -f /tmp/sqs-policy.json /tmp/karpenter-policy.json

eksctl create iamserviceaccount \
  --cluster=$EKS_CLUSTER_NAME \
  --region=$REGION_CODE \
  --name=keda-operator \
  --namespace=$KEDA_NAMESPACE \
  --role-name=skm-keda-operator-role \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/SKMSQSPolicy \
  --override-existing-serviceaccounts \
  --approve || die "keda-operator iamserviceaccount 생성 실패"

eksctl create iamserviceaccount \
  --cluster=$EKS_CLUSTER_NAME \
  --region=$REGION_CODE \
  --name=order-processor-sa \
  --namespace=$APP_NAMESPACE \
  --role-name=skm-order-processor-role \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/SKMSQSPolicy \
  --override-existing-serviceaccounts \
  --approve || die "order-processor-sa iamserviceaccount 생성 실패"

eksctl create iamserviceaccount \
  --cluster=$EKS_CLUSTER_NAME \
  --region=$REGION_CODE \
  --name=karpenter \
  --namespace=$KARPENTER_NAMESPACE \
  --role-name=skm-karpenter-controller-role \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/SKMKarpenterControllerPolicy \
  --override-existing-serviceaccounts \
  --approve || die "karpenter iamserviceaccount 생성 실패"

helm registry logout public.ecr.aws > /dev/null 2>&1 || true
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "$KARPENTER_VERSION" \
  --namespace "$KARPENTER_NAMESPACE" \
  --set "settings.clusterName=$EKS_CLUSTER_NAME" \
  --set "settings.interruptionQueue=" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=karpenter \
  --set replicas=1 \
  --set controller.resources.requests.cpu=200m \
  --set controller.resources.requests.memory=512Mi \
  --set-json "tolerations=[{\"key\":\"$ADDON_TAINT_KEY\",\"operator\":\"Equal\",\"value\":\"$ADDON_TAINT_VALUE\",\"effect\":\"NoSchedule\"},{\"key\":\"CriticalAddonsOnly\",\"operator\":\"Exists\"}]" \
  --wait || die "Karpenter 설치 실패"

helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda \
  --namespace $KEDA_NAMESPACE \
  --set serviceAccount.operator.create=false \
  --set serviceAccount.operator.name=keda-operator \
  --set-json "tolerations=[{\"key\":\"$ADDON_TAINT_KEY\",\"operator\":\"Equal\",\"value\":\"$ADDON_TAINT_VALUE\",\"effect\":\"NoSchedule\"}]" \
  --wait || die "KEDA 설치 실패"

for i in $(seq 1 60); do
  kubectl get crd nodepools.karpenter.sh > /dev/null 2>&1 \
    && kubectl get crd ec2nodeclasses.karpenter.k8s.aws > /dev/null 2>&1 && break
  sleep 5
done
kubectl get crd nodepools.karpenter.sh > /dev/null 2>&1 || die "Karpenter CRD 미등록"

for i in $(seq 1 60); do
  kubectl get crd scaledobjects.keda.sh > /dev/null 2>&1 && break
  sleep 5
done
kubectl get crd scaledobjects.keda.sh > /dev/null 2>&1 || die "KEDA CRD 미등록"

sed -i "s|KARPENTER_NODE_ROLE_NAME|$KARPENTER_NODE_ROLE_NAME|g" /home/ec2-user/eks/manifest/karpenter.yaml
sed -i "s|QUEUE_URL_VALUE|$SQS_QUEUE_URL|g" /home/ec2-user/eks/manifest/deployment.yaml
sed -i "s|QUEUE_URL_VALUE|$SQS_QUEUE_URL|g" /home/ec2-user/eks/manifest/scaledobject.yaml

kubectl apply -f /home/ec2-user/eks/manifest/karpenter.yaml || die "karpenter.yaml 적용 실패"
kubectl apply -f /home/ec2-user/eks/manifest/deployment.yaml || die "deployment.yaml 적용 실패"
kubectl apply -f /home/ec2-user/eks/manifest/scaledobject.yaml || die "scaledobject.yaml 적용 실패"

echo "[INFO] 완료"
