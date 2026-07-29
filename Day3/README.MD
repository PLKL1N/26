### 인프라 구성

```
terraform init
terraform apply --auto-approve -parallelism=100
```

apply가 끝난 후


```
terraform apply -var enable_cloudfront=true -var enable_cloudwatch=true --auto-approve
```