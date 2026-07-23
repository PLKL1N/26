#==================================================================

REGION_CODE=ap-northeast-2
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
SECRET_NAME=$(aws secretsmanager list-secrets --query "SecretList[?Name=='rds-secret'].Name" --output text --region $REGION_CODE)
DB_USER=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".username")
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".password")
DB_HOST=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".host")
DB_PORT=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".port")
DB_DBNAME=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".dbname")
S3_BUCKET=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'apdev-images')].Name" --output text)
PRODUCT_IMAGE=$(aws ecr describe-repositories --repository-names apdev-product --region $REGION_CODE --query 'repositories[0].repositoryUri' --output text)


#==================================================================

cd /home/ec2-user/app/stress
docker build -t apdev-stress:test .

docker run -d --name stress-test \
  -p 8082:8080 \
  apdev-stress:test

sleep 2
docker logs stress-test

curl -w "\nHTTP:%{http_code}\n" http://localhost:8082/healthcheck
curl -w "\nHTTP:%{http_code}\n" -X POST http://localhost:8082/v1/stress \
  -H "Content-Type: application/json" \
  -d '{"requestid":"1","uuid":"u-1","length":256}'


#==================================================================

docker rm -f stress-test


#==================================================================

aws ecr get-login-password --region $REGION_CODE | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com
STRESS_IMAGE=$(aws ecr describe-repositories --repository-names apdev-stress --region $REGION_CODE --query 'repositories[0].repositoryUri' --output text)
docker tag apdev-stress:test $STRESS_IMAGE:latest
docker push $STRESS_IMAGE:latest