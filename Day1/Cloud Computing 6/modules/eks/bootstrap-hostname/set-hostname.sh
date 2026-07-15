#!/bin/sh
set -eu

ROOTFS="/.bottlerocket/rootfs"

TOK="$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 300")"
IID="$(curl -sS -H "X-aws-ec2-metadata-token: ${TOK}" \
        http://169.254.169.254/latest/meta-data/instance-id)"

UD="/.bottlerocket/bootstrap-containers/current/user-data"
SUFFIX="node"
if [ -f "${UD}" ]; then
  RAW="$(tr -cd 'a-zA-Z0-9' < "${UD}")"
  [ -n "${RAW}" ] && SUFFIX="${RAW}"
fi

HOST="gj2026.${IID}.${SUFFIX}.node"
echo "set-hostname: instance=${IID} suffix=${SUFFIX} -> ${HOST}"

chroot "${ROOTFS}" apiclient set "kubernetes.hostname-override=${HOST}"
echo "set-hostname: done -> ${HOST}"
