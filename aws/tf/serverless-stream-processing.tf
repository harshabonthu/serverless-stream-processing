variable "region" {
  default = "eu-west-1"
}

provider "aws" {
  region     = "${var.region}"
}


resource "aws_iam_policy_attachment" "kinesisfullaccess-attach" {
    name = "kinesisfullaccess-attachment"
    roles = ["${aws_iam_role.apigateway_kinesis_role.name}"]
    policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}

resource "aws_iam_role" "apigateway_kinesis_role" {
    name = "apigateway_kinesis_role"
    assume_role_policy = <<EOF
{"Version": "2012-10-17",
      "Statement": [
          { "Action": "sts:AssumeRole",
            "Principal": {
              "Service": "apigateway.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
          }
        ]
      }
      EOF
}

resource "aws_kinesis_stream" "truck-positions-stream-start" {
    name = "truckpositionsstream"
    shard_count = 1
    retention_period = 48
    shard_level_metrics = [
        "IncomingBytes",
        "OutgoingBytes"
    ]
}

resource "aws_kinesis_stream" "truck-positions-stream-after-filter" {
    name = "truckpositionsstreamaf"
    shard_count = 1
    retention_period = 48
    shard_level_metrics = [
        "IncomingBytes",
        "OutgoingBytes"
    ]
}


resource "aws_api_gateway_rest_api" "truck-position-event-api" {
  name = "truck-position-event-api"
  description = "This is my API for demonstration purposes"
}

resource "aws_api_gateway_resource" "streams" {
  rest_api_id = "${aws_api_gateway_rest_api.truck-position-event-api.id}"
  parent_id = "${aws_api_gateway_rest_api.truck-position-event-api.root_resource_id}"
  path_part = "streams"
}

resource "aws_api_gateway_resource" "stream" {
  rest_api_id = "${aws_api_gateway_rest_api.truck-position-event-api.id}"
  parent_id = "${aws_api_gateway_resource.streams.id}"
  path_part = "{stream-name}"
}

resource "aws_api_gateway_resource" "records" {
  rest_api_id = "${aws_api_gateway_rest_api.truck-position-event-api.id}"
  parent_id = "${aws_api_gateway_resource.stream.id}"
  path_part = "records"
}

resource "aws_api_gateway_method" "post-event-method" {
  rest_api_id = "${aws_api_gateway_rest_api.truck-position-event-api.id}"
  resource_id = "${aws_api_gateway_resource.records.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "truck-position-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.truck-position-event-api.id}"
  resource_id = "${aws_api_gateway_resource.records.id}"
  http_method = "${aws_api_gateway_method.post-event-method.http_method}"
  integration_http_method="POST"
  type = "AWS"
  uri = "arn:aws:apigateway:${var.region}:kinesis:action/PutRecord"
  credentials = "${aws_iam_role.apigateway_kinesis_role.arn}"
  request_parameters={ "integration.request.header.Content-Type" = "'application/x-amz-json-1.1'" }

  # Transforms the incoming XML request to JSON
  request_templates {
    "application/json" = <<EOF
{
  "StreamName" : "$input.params('stream-name')",
  "Data" : "$util.base64Encode($input.path('$.Data'))",
  "PartitionKey" : "$input.path('$.PartitionKey')"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.truck-position-event-api.id}"
  resource_id = "${aws_api_gateway_resource.records.id}"
  http_method = "${aws_api_gateway_method.post-event-method.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "truck-position-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.truck-position-event-api.id}"
  resource_id = "${aws_api_gateway_resource.records.id}"
  http_method = "${aws_api_gateway_method.post-event-method.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  }


resource "aws_api_gateway_deployment" "truck-position-event-api-deployment" {
  depends_on = ["aws_api_gateway_method_response.200"]

  rest_api_id = "${aws_api_gateway_rest_api.truck-position-event-api.id}"
  stage_name = "test"

  variables = {
    "answer" = "42"
  }
}
