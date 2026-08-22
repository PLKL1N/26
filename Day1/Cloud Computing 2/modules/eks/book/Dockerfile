FROM alpine:3.22 AS build
RUN apk add --no-cache upx ca-certificates tzdata
COPY book /book
RUN chmod +x /book && upx --best --lzma /book

FROM alpine:3.22
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build /book /book
ENV TZ=Asia/Seoul
EXPOSE 8080
ENTRYPOINT ["/book"]
