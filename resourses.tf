data "aws_s3_bucket" "bucket" {
  bucket = "irashoemo.com"
}

data "aws_route53_zone" "bucket_zone" {
  name = "irashoemo.com."
}

resource "aws_route53_record" "zone_record" {
  zone_id = data.aws_route53_zone.bucket_zone.id
  name    = "bucket"
  type    = "A"

  alias {
    name    = data.aws_s3_bucket.bucket.website_domain
    zone_id = data.aws_s3_bucket.bucket.hosted_zone_id
    evaluate_target_health = false
  }
}

data "aws_dynamodb_table" "Visitors" {
  name = "Visitors"
}

resource "aws_dynamodb_table_item" "crc_visit_count_item" {
  table_name = data.aws_dynamodb_table.Visitors.id
  hash_key   = data.aws_dynamodb_table.Visitors.hash_key

  item = <<ITEM
{
  "id": {"S": "1"},
  "count": {"N": "1"}
}
ITEM

  lifecycle {
    ignore_changes = [item]
  }
}

resource "aws_api_gateway_rest_api" "visitor-api" {
  name        = "visitor-api"
  description = "Cloud Resume Challenge API Gateway"
}

# --- Get resource --- #
resource "aws_api_gateway_resource" "get_resource" {
  rest_api_id = aws_api_gateway_rest_api.visitor-api.id
  parent_id   = aws_api_gateway_rest_api.visitor-api.root_resource_id
  path_part   = "visitors"
}

resource "aws_api_gateway_resource" "get_mainpath" {
  rest_api_id = aws_api_gateway_rest_api.visitor-api.id
  parent_id   = aws_api_gateway_resource.get_resource.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.visitor-api.id
  resource_id   = aws_api_gateway_resource.get_mainpath.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "put_count_integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor-api.id
  resource_id             = aws_api_gateway_resource.get_mainpath.id
  http_method             = aws_api_gateway_method.get_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = data.aws_lambda_function.visitorCounter.invoke_arn

  depends_on = [aws_api_gateway_method.get_method, data.aws_lambda_function.visitorCounter]
}


resource "aws_api_gateway_method_response" "get_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor-api.id
  resource_id = aws_api_gateway_resource.get_mainpath.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = [aws_api_gateway_method.get_method]
}

resource "aws_api_gateway_deployment" "crc_api_deployment_post" {
  rest_api_id = aws_api_gateway_rest_api.visitor-api.id
  stage_name  = "dev"

  depends_on = [aws_api_gateway_integration.put_count_integration]
}

resource "aws_api_gateway_method_settings" "get_count" {
  rest_api_id = aws_api_gateway_rest_api.visitor-api.id
  stage_name  = aws_api_gateway_deployment.crc_api_deployment_post.stage_name
  method_path = "${aws_api_gateway_resource.get_mainpath.path_part}/${aws_api_gateway_method.get_method.http_method}"

  settings {}
}


# --- Configuring and provisioning lambda function --- #
data "aws_iam_role" "crc_iam_role_lambda" {
  name = "dynamodb_all_role"
}

resource "aws_iam_role_policy_attachment" "lambda_for_dynamo_db" {
  role = data.aws_iam_role.crc_iam_role_lambda.name
  policy_arn = "arn:aws:iam::695411911306:policy/dynamodb_all"
}

data "archive_file" "visitorCounter" {
  type        = "zip"
  source_file = "visitorCounter.js"
  output_path = "visitorCounter.zip"
}

variable "visitorCounter" {
  type = string
}

data "aws_lambda_function" "visitorCounter" {
  function_name = var.visitorCounter
}

resource "aws_lambda_permission" "add_count_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.visitorCounter.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor-api.execution_arn}/*/${aws_api_gateway_method.get_method.http_method}/visitors/*"
}