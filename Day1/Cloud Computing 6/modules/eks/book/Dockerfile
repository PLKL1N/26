FROM alpine:3.20 AS build
RUN apk add --no-cache upx ca-certificates
COPY book /book
RUN chmod +x /book && upx --best --lzma /book
FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /book /book
EXPOSE 8080
ENTRYPOINT ["/book"]
