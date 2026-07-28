FROM alpine:3.20
RUN apk add --no-cache curl
COPY set-hostname.sh /set-hostname.sh
RUN sed -i 's/\r$//' /set-hostname.sh && chmod +x /set-hostname.sh
ENTRYPOINT ["/set-hostname.sh"]