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

cd /home/ec2-user/app/product
docker build -t apdev-product:test .

docker run -d --name product-test \
  -e MYSQL_USER=$DB_USER \
  -e MYSQL_PASSWORD=$DB_PASSWORD \
  -e MYSQL_HOST=$DB_HOST \
  -e MYSQL_PORT=$DB_PORT \
  -e MYSQL_DBNAME=$DB_DBNAME \
  -e S3_BUCKET=$S3_BUCKET \
  -p 8081:8080 \
  apdev-product:test

sleep 2
docker logs product-test
curl http://localhost:8081/healthcheck


#==================================================================

curl -w "\nHTTP:%{http_code}\n" -X POST http://localhost:8081/v1/product \
  -H "Content-Type: application/json" \
  -d '{"requestid":"1","uuid":"u-1","id":"test001","name":"testitem","price":1000}'

curl -w "\nHTTP:%{http_code}\n" "http://localhost:8081/v1/product?id=test001"


#==================================================================

docker rm -f product-test
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p"$DB_PASSWORD" $DB_DBNAME \
  -e "DELETE FROM product WHERE id='test001';"


#==================================================================

aws ecr get-login-password --region $REGION_CODE | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com
PRODUCT_IMAGE=$(aws ecr describe-repositories --repository-names apdev-product --region $REGION_CODE --query 'repositories[0].repositoryUri' --output text)
docker tag apdev-product:test $PRODUCT_IMAGE:latest
docker push $PRODUCT_IMAGE:latest