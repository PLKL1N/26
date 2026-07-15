#!/bin/bash
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="gj2026-eks-cluster"
VPC_NAME="gj2026-vpc"
PRIVATE_A_SN_NAME="gj2026-private-subnet-a"
PRIVATE_B_SN_NAME="gj2026-private-subnet-b"
EKS_KMS_ALIAS="alias/gj2026-eks-key"

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query "Vpcs[].VpcId" --output text --region $REGION_CODE)
PRIVATE_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_B_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_B_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
EKS_KEY_ARN=$(aws kms describe-key --key-id $EKS_KMS_ALIAS --query "KeyMetadata.Arn" --output text --region $REGION_CODE)
CLUSTER_YAML_PATH=$(sudo find / -name "cluster.yaml" 2>/dev/null | head -n1)

sed -i "s|VPC_ID|$VPC_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PRIVATE_A|$PRIVATE_A_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PRIVATE_B|$PRIVATE_B_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|EKS_KEY_ARN|$EKS_KEY_ARN|g" $CLUSTER_YAML_PATH

PRIVATE_SN_IDS=("$PRIVATE_A_SN_ID" "$PRIVATE_B_SN_ID")
for name in "${PRIVATE_SN_IDS[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/cluster/$EKS_CLUSTER_NAME,Value=shared --region $REGION_CODE
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/internal-elb,Value=1 --region $REGION_CODE
done
