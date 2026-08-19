
cd /home/ec2-user/app/user
cat > Dockerfile << 'EOF'
FROM gcr.io/distroless/base-debian12:nonroot
WORKDIR /app
ENV TZ=Asia/Seoul
COPY --chmod=755 ./user /app/app
USER nonroot
EXPOSE 8080
ENTRYPOINT ["/app/app"]
EOF

cd /home/ec2-user/app/product
cat > Dockerfile << 'EOF'
FROM gcr.io/distroless/base-debian12:nonroot
WORKDIR /app
ENV TZ=Asia/Seoul
COPY --chmod=755 ./product /app/app
USER nonroot
EXPOSE 8080
ENTRYPOINT ["/app/app"]
EOF

cd /home/ec2-user/app/stress
cat > Dockerfile << 'EOF'
FROM gcr.io/distroless/base-debian12:nonroot
WORKDIR /app
ENV TZ=Asia/Seoul
COPY --chmod=755 ./stress /app/app
USER nonroot
EXPOSE 8080
ENTRYPOINT ["/app/app"]
EOF