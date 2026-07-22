#==================================================================

REGION_CODE=ap-northeast-2
ACCOUNT_ID=$(aws sts get caller-identity --query Account --output text)
SECRET_NAME=$(aws secretsmanager list-secrets --query "SecretList[?Name=='rds-secret'].Name" --output text --region $REGION_CODE)
DB_USER=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".username")
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".password")
DB_HOST=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".host")
DB_PORT=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".port")
DB_DBNAME=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text --region $REGION_CODE | jq -r ".dbname")
S3_BUCKET=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'apdev-images')].Name" --output text)
PRODUCT_IMAGE=$(aws ecr describe-repositories --repository-names apdev-product --region $REGION_CODE --query 'repositories[0].repositoryUri' --output text)


#==================================================================

cd /home/ec2-user/app/user
docker build -t apdev-user:test .

docker run -d --name user-test \
  -e MYSQL_USER=$DB_USER \
  -e MYSQL_PASSWORD=$DB_PASSWORD \
  -e MYSQL_HOST=$DB_HOST \
  -e MYSQL_PORT=$DB_PORT \
  -e MYSQL_DBNAME=$DB_DBNAME \
  -p 8080:8080 \
  apdev-user:test

sleep 2
docker logs user-test
curl http://localhost:8080/healthcheck
curl -w "\nHTTP:%{http_code}\n" -X POST http://localhost:8080/v1/user \
  -H "Content-Type: application/json" \
  -d '{"requestid":"1","uuid":"u-1","username":"testuser1","email":"testuser1@example.org"}'
curl -w "\nHTTP:%{http_code}\n" "http://localhost:8080/v1/user?email=testuser1@example.org"


#==================================================================

docker rm -f user-test
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p"$DB_PASSWORD" $DB_DBNAME \
  -e "DELETE FROM user WHERE username='testuser1';"


#==================================================================

aws ecr get-login-password --region $REGION_CODE | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com
USER_IMAGE=$(aws ecr describe-repositories --repository-names apdev-user --region $REGION_CODE --query 'repositories[0].repositoryUri' --output text)
docker tag apdev-user:test $USER_IMAGE:latest
docker push $USER_IMAGE:latest