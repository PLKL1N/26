#!/bin/bash
set -o pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION_CODE="us-west-2"
EKS_CLUSTER_NAME="skills-sqs-cluster"
SQS_NAME="skills-sqs-queue"
EKS_NODE_GROUP_NAME="skills-sqs-node"
SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name $SQS_NAME --query "QueueUrl" --output text)

CLUSTER_YAML_PATH=$(sudo find / -name "cluster.yaml" 2>/dev/null)

die() { echo "[FATAL] $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# eksctl 이 만드는 Karpenter IAM 리소스는 terraform state 밖에 있어서
# terraform destroy 후에도 남는다. 남아 있으면 karpenter 스택이
# "AWS::IAM::Role ... already exists" 로 ROLLBACK 되므로 미리 정리한다.
# ---------------------------------------------------------------------------
cleanup_stale_karpenter_iam() {
  local ROLE="eksctl-KarpenterNodeRole-${EKS_CLUSTER_NAME}"
  local PROFILE="eksctl-KarpenterNodeInstanceProfile-${EKS_CLUSTER_NAME}"
  local STACK="eksctl-${EKS_CLUSTER_NAME}-karpenter"

  # ROLLBACK_COMPLETE 등으로 남은 스택 제거
  local STACK_STATUS
  STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK" \
    --region "$REGION_CODE" --query "Stacks[0].StackStatus" --output text 2>/dev/null)
  if [ -n "$STACK_STATUS" ] && [ "$STACK_STATUS" != "None" ]; then
    echo "[INFO] 기존 karpenter 스택($STACK_STATUS) 삭제 중"
    aws cloudformation delete-stack --stack-name "$STACK" --region "$REGION_CODE"
    aws cloudformation wait stack-delete-complete --stack-name "$STACK" --region "$REGION_CODE" 2>/dev/null
  fi

  # 노드 롤 정리
  # 주의: Karpenter v1.x 는 인스턴스 프로파일을 스스로 만들며 이름이
  # "<cluster>_<hash>" 형태라 eksctl 규칙과 다르다. 고정 이름만 지우면
  # 롤이 프로파일에 물린 채 남아 delete-role 이 DeleteConflict 로 실패한다.
  # 따라서 list-instance-profiles-for-role 로 전부 찾아서 분리한다.
  if aws iam get-role --role-name "$ROLE" > /dev/null 2>&1; then
    echo "[INFO] 잔여 IAM 롤 정리 시작: $ROLE"

    for P in $(aws iam list-instance-profiles-for-role --role-name "$ROLE" \
                 --query 'InstanceProfiles[].InstanceProfileName' --output text); do
      echo "[INFO]   프로파일에서 분리: $P"
      aws iam remove-role-from-instance-profile --instance-profile-name "$P" --role-name "$ROLE" \
        || die "인스턴스 프로파일 분리 실패: $P"
      aws iam delete-instance-profile --instance-profile-name "$P" \
        || die "인스턴스 프로파일 삭제 실패: $P"
    done

    for p in $(aws iam list-attached-role-policies --role-name "$ROLE" \
                 --query 'AttachedPolicies[].PolicyArn' --output text); do
      aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$p" \
        || die "정책 분리 실패: $p"
    done
    for p in $(aws iam list-role-policies --role-name "$ROLE" \
                 --query 'PolicyNames' --output text); do
      aws iam delete-role-policy --role-name "$ROLE" --policy-name "$p" \
        || die "인라인 정책 삭제 실패: $p"
    done

    aws iam delete-role --role-name "$ROLE" || die "IAM 롤 삭제 실패: $ROLE"
    echo "[INFO] 롤 삭제 완료: $ROLE"
  fi

  # 이름이 남아 있으면 CFN 이 AlreadyExists 로 실패하므로 소멸까지 대기
  for i in $(seq 1 30); do
    aws iam get-role --role-name "$ROLE" > /dev/null 2>&1 || break
    sleep 2
  done
  aws iam get-role --role-name "$ROLE" > /dev/null 2>&1 \
    && die "IAM 롤이 여전히 존재합니다: $ROLE"

  # 고정 이름 인스턴스 프로파일이 롤 없이 남아 있는 경우도 정리
  if aws iam get-instance-profile --instance-profile-name "$PROFILE" > /dev/null 2>&1; then
    echo "[INFO] 잔여 인스턴스 프로파일 삭제: $PROFILE"
    for r in $(aws iam get-instance-profile --instance-profile-name "$PROFILE" \
                 --query 'InstanceProfile.Roles[].RoleName' --output text); do
      aws iam remove-role-from-instance-profile --instance-profile-name "$PROFILE" --role-name "$r"
    done
    aws iam delete-instance-profile --instance-profile-name "$PROFILE" \
      || die "인스턴스 프로파일 삭제 실패: $PROFILE"
  fi

  # 컨트롤러 관리형 정책 정리
  local POLICY_ARN
  POLICY_ARN=$(aws iam list-policies --scope Local \
    --query "Policies[?PolicyName=='eksctl-KarpenterControllerPolicy-${EKS_CLUSTER_NAME}'].Arn" \
    --output text)
  if [ -n "$POLICY_ARN" ] && [ "$POLICY_ARN" != "None" ]; then
    echo "[INFO] 잔여 관리형 정책 삭제: $POLICY_ARN"
    for e in $(aws iam list-entities-for-policy --policy-arn "$POLICY_ARN" \
                 --query 'PolicyRoles[].RoleName' --output text); do
      aws iam detach-role-policy --role-name "$e" --policy-arn "$POLICY_ARN"
    done
    for v in $(aws iam list-policy-versions --policy-arn "$POLICY_ARN" \
                 --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text); do
      aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$v"
    done
    aws iam delete-policy --policy-arn "$POLICY_ARN" || die "관리형 정책 삭제 실패: $POLICY_ARN"
  fi
}

cleanup_stale_karpenter_iam

# ---------------------------------------------------------------------------
# 클러스터 생성 — 여기서 실패하면 뒤 단계는 전부 무의미하므로 즉시 중단
# ---------------------------------------------------------------------------
eksctl create cluster -f $CLUSTER_YAML_PATH || die "eksctl create cluster 실패. CloudFormation 이벤트를 확인하세요."

aws eks --region $REGION_CODE update-kubeconfig --name $EKS_CLUSTER_NAME || die "update-kubeconfig 실패"
su - ec2-user -c 'REGION_CODE="us-west-2"; EKS_CLUSTER_NAME="skills-sqs-cluster"; aws eks --region $REGION_CODE update-kubeconfig --name $EKS_CLUSTER_NAME'

aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$ACCOUNT_ID:user/wsc-user --region $REGION_CODE > /dev/null 2>&1 || true
aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$ACCOUNT_ID:user/wsc-user --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster --region $REGION_CODE > /dev/null 2>&1 || true

kubectl create ns skills-sqs || true

/home/ec2-user/scripts/karpenter-tag.sh || die "karpenter-tag.sh 실패"

# ---------------------------------------------------------------------------
# EC2NodeClass 의 role 에는 "노드 롤" 하나만 들어가야 한다.
# grep -i karpenter 로는 KarpenterControllerRole 까지 잡혀 여러 줄이 되므로
# 정확한 이름으로 조회한다.
# ---------------------------------------------------------------------------
KARPENTER_ROLE_NAME="eksctl-KarpenterNodeRole-${EKS_CLUSTER_NAME}"
aws iam get-role --role-name "$KARPENTER_ROLE_NAME" > /dev/null 2>&1 \
  || KARPENTER_ROLE_NAME=$(aws iam list-roles --query 'Roles[].RoleName' --output text \
       | tr '\t' '\n' | grep -i 'KarpenterNodeRole' | head -n 1)

[ -n "$KARPENTER_ROLE_NAME" ] || die "Karpenter 노드 롤을 찾을 수 없습니다."
echo "[INFO] KARPENTER_ROLE_NAME=$KARPENTER_ROLE_NAME"

sed -i "s|KARPENTER_ROLE_NAME|$KARPENTER_ROLE_NAME|g" /home/ec2-user/eks/manifest/karpenter.yaml
sed -i "s|SQS_QUEUE_URLS|$SQS_QUEUE_URL|g" /home/ec2-user/eks/manifest/deployment.yaml
sed -i "s|SQS_QUEUE_URL|$SQS_QUEUE_URL|g" /home/ec2-user/eks/manifest/scaledobject.yaml

cat << EOF > /home/ec2-user/eks/manifest/sqs-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GetQueueAttributes",
            "Effect": "Allow",
            "Action": [
                "sqs:GetQueueAttributes",
                "sqs:ReceiveMessage",
                "sqs:GetQueueUrl",
                "sqs:ListQueues",
                "sqs:deletemessage"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy --policy-name SQSPolicy --policy-document file:///home/ec2-user/eks/manifest/sqs-policy.json > /dev/null 2>&1 || true

rm -rf /home/ec2-user/eks/manifest/sqs-policy.json

eksctl create iamserviceaccount \
  --cluster=$EKS_CLUSTER_NAME \
  --region=$REGION_CODE \
  --name=keda-operator \
  --namespace=keda \
  --role-name=keda-operator-role \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/SQSPolicy \
  --approve || die "keda-operator iamserviceaccount 생성 실패"

eksctl create iamserviceaccount \
  --cluster=$EKS_CLUSTER_NAME \
  --region=$REGION_CODE \
  --name=sqs-worker-sa \
  --namespace=skills-sqs \
  --role-name=sqs-worker-role \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/SQSPolicy \
  --approve || die "sqs-worker-sa iamserviceaccount 생성 실패"

helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda \
  -n keda \
  --set serviceAccount.operator.create=false \
  --set serviceAccount.operator.name=keda-operator || die "KEDA 설치 실패"

# Karpenter CRD 가 등록될 때까지 대기 (고정 sleep 대신 실제 조건 확인)
echo "[INFO] Karpenter CRD 대기 중"
for i in $(seq 1 60); do
  if kubectl get crd nodepools.karpenter.sh > /dev/null 2>&1 \
     && kubectl get crd ec2nodeclasses.karpenter.k8s.aws > /dev/null 2>&1; then
    echo "[INFO] Karpenter CRD 확인됨"
    break
  fi
  sleep 5
done
kubectl get crd nodepools.karpenter.sh > /dev/null 2>&1 || die "Karpenter CRD 가 등록되지 않았습니다."

# KEDA CRD 대기
for i in $(seq 1 60); do
  kubectl get crd scaledobjects.keda.sh > /dev/null 2>&1 && break
  sleep 5
done

kubectl apply -f /home/ec2-user/eks/manifest/karpenter.yaml || die "karpenter.yaml 적용 실패"
kubectl apply -f /home/ec2-user/eks/manifest/deployment.yaml || die "deployment.yaml 적용 실패"
kubectl apply -f /home/ec2-user/eks/manifest/triggerauthentication.yaml || die "triggerauthentication.yaml 적용 실패"
kubectl apply -f /home/ec2-user/eks/manifest/scaledobject.yaml || die "scaledobject.yaml 적용 실패"

echo "[INFO] 완료"
