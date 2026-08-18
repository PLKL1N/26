#!/bin/bash
set -o pipefail
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="skm-eks-cluster"
PRIVATE_A_SN_NAME="skm-private-a"
PRIVATE_C_SN_NAME="skm-private-c"

PRIVATE_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_C_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_C_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)

CLUSTER_SECURITY_GROUP_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text --region $REGION_CODE)

aws ec2 create-tags --resources $CLUSTER_SECURITY_GROUP_ID --tags Key=karpenter.sh/discovery,Value=$EKS_CLUSTER_NAME --region $REGION_CODE

SN_IDS=("$PRIVATE_A_SN_ID" "$PRIVATE_C_SN_ID")

for name in "${SN_IDS[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=karpenter.sh/discovery,Value=$EKS_CLUSTER_NAME --region $REGION_CODE
done
