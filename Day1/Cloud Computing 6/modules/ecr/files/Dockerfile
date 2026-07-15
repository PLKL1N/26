# book 애플리케이션 이미지 (3MB 제한 충족: scratch + UPX 압축 바이너리)
# - 정적 Go 바이너리이므로 베이스 OS 불필요 (FROM scratch)
# - DynamoDB(HTTPS) 호출 시 TLS 검증을 위해 CA 번들을 반드시 포함
# - 환경변수 AWS_REGION / TABLE_NAME 은 이미지에 굽지 않고
#   배포(Deployment, 8번)에서 주입한다.
FROM scratch

# TLS 루트 인증서 (없으면 DynamoDB 호출이 x509 오류로 실패)
COPY ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# 애플리케이션 바이너리
COPY book /book

# /health (GET), /v1/book (POST) 를 8000 포트에서 서비스
EXPOSE 8000

ENTRYPOINT ["/book"]
