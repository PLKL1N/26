# 매우 작은 bootstrap container (curl 만 필요)
FROM alpine:3.20
RUN apk add --no-cache curl
COPY set-hostname.sh /set-hostname.sh
RUN chmod +x /set-hostname.sh
ENTRYPOINT ["/set-hostname.sh"]
