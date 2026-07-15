#!/bin/bash
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="gj2026-eks-cluster"
CLUSTER_YAML_PATH=$(sudo find / -name "cluster.yaml" 2>/dev/null | head -n1)
SCRIPT_DIR="$(dirname "$0")"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION_CODE}.amazonaws.com"

open_sg() {
  local CSG BSG
  CSG=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $REGION_CODE --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text 2>/dev/null)
  BSG=$(aws ec2 describe-security-groups --region $REGION_CODE --filters Name=group-name,Values=gj2026-mgmt-bastion-sg --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
  [ -n "$CSG" ] && [ -n "$BSG" ] && aws ec2 authorize-security-group-ingress --region $REGION_CODE --group-id $CSG --protocol tcp --port 443 --source-group $BSG 2>/dev/null || true
}

build_set_hostname_image() {
  echo ">> [4-3] building set-hostname bootstrap image"
  aws ecr create-repository --repository-name gj2026-set-hostname --region $REGION_CODE 2>/dev/null || true
  aws ecr get-login-password --region $REGION_CODE | docker login --username AWS --password-stdin "$ECR" 2>/dev/null
  local BDIR
  BDIR=$(sudo find / -type d -name "bootstrap-hostname" 2>/dev/null | head -n1)
  docker build -t ${ECR}/gj2026-set-hostname:latest "$BDIR"
  docker push ${ECR}/gj2026-set-hostname:latest
  sed -i "s|SET_HOSTNAME_IMAGE|${ECR}/gj2026-set-hostname:latest|g" "$CLUSTER_YAML_PATH"
}

patch_aws_auth() {
  echo ">> [4-3] patching aws-auth usernames"
  local ADDON_ROLE APP_ROLE
  ADDON_ROLE=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name gj2026-eks-addon-nodegroup --region $REGION_CODE --query 'nodegroup.nodeRole' --output text 2>/dev/null)
  APP_ROLE=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name gj2026-eks-app-nodegroup --region $REGION_CODE --query 'nodegroup.nodeRole' --output text 2>/dev/null)

  for R in "$ADDON_ROLE" "$APP_ROLE"; do
    [ -n "$R" ] && [ "$R" != "None" ] && \
      aws eks delete-access-entry --cluster-name $EKS_CLUSTER_NAME --region $REGION_CODE \
        --principal-arn "$R" 2>/dev/null || true
  done

  kubectl -n kube-system get cm aws-auth -o yaml | grep -v "resourceVersion:" > /tmp/aa.yaml
  python3 - "$ADDON_ROLE" "$APP_ROLE" <<'PY'
import sys, yaml
addon, app = sys.argv[1], sys.argv[2]
f="/tmp/aa.yaml"
d=yaml.safe_load(open(f))
roles=yaml.safe_load(d["data"].get("mapRoles","[]")) or []
uniq={}
for r in roles:
    ra=r.get("rolearn")
    if ra in uniq and "gj2026." not in r.get("username",""):
        continue
    uniq[ra]=r
roles=list(uniq.values())
def ensure(role, uname):
    for r in roles:
        if r.get("rolearn")==role:
            r["username"]=uname
            r["groups"]=["system:bootstrappers","system:nodes"]
            return
    roles.append({"rolearn":role,"username":uname,"groups":["system:bootstrappers","system:nodes"]})
if addon and addon!="None": ensure(addon,"system:node:gj2026.{{SessionName}}.addon.node")
if app and app!="None":     ensure(app,  "system:node:gj2026.{{SessionName}}.app.node")
d["data"]["mapRoles"]=yaml.safe_dump(roles, default_flow_style=False)
yaml.safe_dump(d, open(f,"w"), default_flow_style=False)
PY
  kubectl -n kube-system replace -f /tmp/aa.yaml
}

STATUS=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $REGION_CODE --query 'cluster.status' --output text 2>/dev/null || echo "NONE")

if [ "$STATUS" = "ACTIVE" ]; then
  echo ">> cluster already ACTIVE, skipping create"
else
  sudo bash "$SCRIPT_DIR/cluster-tag.sh"

  build_set_hostname_image

  eksctl create cluster -f "$CLUSTER_YAML_PATH" --without-nodegroup &
  EKSCTL_PID=$!
  echo ">> waiting for cluster control plane to become ACTIVE..."
  until [ "$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $REGION_CODE --query 'cluster.status' --output text 2>/dev/null)" = "ACTIVE" ]; do
    if ! kill -0 $EKSCTL_PID 2>/dev/null; then echo ">> eksctl(control-plane) exited"; break; fi
    sleep 15
  done
  open_sg
  wait $EKSCTL_PID || true

  kubectl get nodes >/dev/null 2>&1

  eksctl create nodegroup -f "$CLUSTER_YAML_PATH" &
  NG_PID=$!

  echo ">> [4-3] resilient aws-auth patch loop..."
  ( for i in $(seq 1 120); do
      AR=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name gj2026-eks-addon-nodegroup --region $REGION_CODE --query 'nodegroup.nodeRole' --output text 2>/dev/null)
      PR=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name gj2026-eks-app-nodegroup --region $REGION_CODE --query 'nodegroup.nodeRole' --output text 2>/dev/null)
      if [ -n "$AR" ] && [ "$AR" != "None" ] && [ -n "$PR" ] && [ "$PR" != "None" ]; then
        patch_aws_auth
        READY=$(kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers 2>/dev/null | grep -c "^gj2026\.")
        [ "${READY:-0}" -ge 4 ] && { echo ">> [4-3] custom-named nodes joined: $READY"; break; }
      fi
      sleep 15
    done ) &
  PATCH_PID=$!

  wait $NG_PID || true
  wait $PATCH_PID 2>/dev/null || true
fi

open_sg
aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME --region $REGION_CODE --principal-arn arn:aws:iam::${ACCOUNT_ID}:root 2>/dev/null || true
aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME --region $REGION_CODE --principal-arn arn:aws:iam::${ACCOUNT_ID}:root --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster 2>/dev/null || true

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $REGION_CODE
su - ec2-user -c "aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $REGION_CODE"

echo ">> nodes:"
kubectl get nodes
