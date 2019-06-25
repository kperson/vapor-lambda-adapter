data "aws_caller_identity" "current" {}

variable "swift_lambda_layer" {
  type    = "string"
  default = "arn:aws:lambda:us-east-1:193125195061:layer:swift5:5"
}
