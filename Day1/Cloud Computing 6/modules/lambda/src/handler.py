import json
import os
import boto3
from boto3.dynamodb.conditions import Key

REGION = os.environ.get("AWS_REGION", "ap-northeast-2")
TABLE_NAME = os.environ["TABLE_NAME"]
GSI_NAME = os.environ.get("GSI_NAME", "client_id-index")
METRIC_NAMESPACE = os.environ.get("METRIC_NAMESPACE", "gj2026/book-reservation")

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)
cw = boto3.client("cloudwatch", region_name=REGION)

FIELDS = ["username", "email", "concert_name"]


def _project(items):
    return [{k: it.get(k) for k in FIELDS} for it in items]


def _put_metric(client_id):
    for dim_value in (client_id, "ALL"):
        cw.put_metric_data(
            Namespace=METRIC_NAMESPACE,
            MetricData=[{
                "MetricName": "Invocations",
                "Dimensions": [{"Name": "client_id", "Value": dim_value}],
                "Value": 1,
                "Unit": "Count",
            }],
        )


def handler(event, context):
    params = event.get("queryStringParameters") or {}
    client_id = params.get("client_id")

    if client_id:
        resp = table.query(
            IndexName=GSI_NAME,
            KeyConditionExpression=Key("client_id").eq(client_id),
        )
        items = resp.get("Items", [])
    else:
        items = table.scan().get("Items", [])

    _put_metric(client_id if client_id else "ALL")

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(_project(items), ensure_ascii=False),
    }
