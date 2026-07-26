### 인프라 구성
<br>
```
terraform init
terraform apply --auto-approve -parallelism=100
```
<br>
apply 후 RDS 생성이 끝났다면 Docker 구성
<br>
Docker 구성 후 EKS 생성이 끝났다면 Kubernetes 구성
<br>
```
terraform apply -var enable_cloudfront=true -var enable_cloudwatch=true --auto-approve
```