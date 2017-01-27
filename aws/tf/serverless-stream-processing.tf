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

resource "aws_kinesis_stream" "truck-positions-stream" {
    name = "truckpositionsstream"
    shard_count = 1
    retention_period = 48
    shard_level_metrics = [
        "IncomingBytes",
        "OutgoingBytes"
    ]
}
