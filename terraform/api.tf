resource "aws_appsync_graphql_api" "last-dram-api" {
  authentication_type = "API_KEY"
  name                = "last-dram-api"
  schema              = file("../schema.graphql")
}

resource "aws_appsync_api_key" "api-key" {
  api_id  = aws_appsync_graphql_api.last-dram-api.id
  expires = "2023-02-05T00:00:00Z"
}

resource "aws_appsync_resolver" "getBottle-resolver" {
  api_id      = aws_appsync_graphql_api.last-dram-api.id
  field       = "getBottle"
  type        = "Query"
  data_source = aws_appsync_datasource.bottles-datasource.name

  request_template  = file("resolver-templates/GetItem.vtl")
  response_template = "$util.toJson($context.result)"
}

resource "aws_appsync_resolver" "listBottles-resolver" {
  api_id      = aws_appsync_graphql_api.last-dram-api.id
  field       = "listBottles"
  type        = "Query"
  data_source = aws_appsync_datasource.bottles-datasource.name

  request_template  = file("resolver-templates/Scan.vtl")
  response_template = "$util.toJson($context.result)"
}

resource "aws_appsync_resolver" "createBottle-resolver" {
  api_id      = aws_appsync_graphql_api.last-dram-api.id
  field       = "createBottle"
  type        = "Mutation"
  data_source = aws_appsync_datasource.bottles-datasource.name

  request_template  = file("resolver-templates/PutItem.vtl")
  response_template = "$util.toJson($context.result)"
}

resource "aws_appsync_resolver" "updateBottle-resolver" {
  api_id      = aws_appsync_graphql_api.last-dram-api.id
  field       = "updateBottle"
  type        = "Mutation"
  data_source = aws_appsync_datasource.bottles-datasource.name

  request_template  = file("resolver-templates/UpdateItem.vtl")
  response_template = "$util.toJson($context.result)"
}

resource "aws_appsync_resolver" "deleteBottle-resolver" {
  api_id      = aws_appsync_graphql_api.last-dram-api.id
  field       = "deleteBottle"
  type        = "Mutation"
  data_source = aws_appsync_datasource.bottles-datasource.name

  request_template  = file("resolver-templates/DeleteItem.vtl")
  response_template = "$util.toJson($context.result)"
}

resource "aws_appsync_datasource" "bottles-datasource" {
  api_id           = aws_appsync_graphql_api.last-dram-api.id
  name             = "bottles_datasource"
  service_role_arn = aws_iam_role.last-dram-dynamodb-role.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.bottles-table.name
  }
}

resource "aws_dynamodb_table" "bottles-table" {
  name           = "Bottles"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "user-bottles-table" {
  name           = "UserBottles"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}