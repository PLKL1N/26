#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

REGION="${AWS_REGION:-ap-northeast-2}"
REPO="${REPO:-book}"
TAG="${TAG:-v1.0.1}"
COMPRESS="${COMPRESS:-true}"   # 3MB 제한 충족을 위해 기본 활성화
SRC_BIN="../../artifacts/files/book-linux-amd64_v1.0.1"
CA_SRC="${CA_SRC:-/etc/ssl/certs/ca-certificates.crt}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE="${ECR}/${REPO}:${TAG}"

echo ">> [1/5] 빌드 컨텍스트 준비"
rm -rf build && mkdir -p build
cp "$SRC_BIN" build/book
chmod +x build/book
cp "$CA_SRC" build/ca-certificates.crt
cp Dockerfile build/Dockerfile

if [ "$COMPRESS" = "true" ]; then
  echo ">> [2/5] UPX 압축 (8.7MB -> ~2.5MB)"
  command -v upx >/dev/null 2>&1 || { echo "ERROR: upx 미설치. 'sudo apt-get install -y upx-ucl'"; exit 1; }
  upx --best --lzma build/book
else
  echo ">> [2/5] 압축 생략 (COMPRESS=false) — 3MB 초과 가능성 있음"
fi

echo ">> [3/5] ECR 로그인: ${ECR}"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR"

echo ">> [4/5] 빌드 & 푸시: ${IMAGE}"
docker build -t "$IMAGE" build
docker push "$IMAGE"

echo ">> [5/5] ECR 이미지 크기 검증 (<= 3MB)"
SIZE="$(aws ecr describe-images --repository-name "$REPO" \
        --image-ids imageTag="$TAG" --region "$REGION" \
        --query 'imageDetails[0].imageSizeInBytes' --output text)"
MB="$(awk "BEGIN{printf \"%.2f\", ${SIZE}/1048576}")"
echo "   imageSizeInBytes = ${SIZE} (${MB} MB)"
if [ "${SIZE}" -gt 3145728 ]; then
  echo "   !! 경고: 3MB 초과 — COMPRESS=true 인지 확인하세요."
  exit 1
else
  echo "   OK: 3MB 이하"
fi

echo ">> 완료: ${IMAGE}"
