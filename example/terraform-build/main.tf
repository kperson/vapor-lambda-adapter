locals {
  app_envs = {
    EXECUTABLE = "VaporApp"
  }
  layers = [
    "${var.swift_lambda_layer}"
  ]
}

module "docker_build" {
  source      = "./modules/docker-build"
  working_dir = "../"
  docker_file = "Dockerfile"
}

module "extract_executable" {
  source         = "./modules/docker-extract"
  container_file = "/code/.lambda-build/x86_64-unknown-linux/release/VaporApp"
  output_file    = "VaporApp"
  tag            = "${module.docker_build.docker_tag}"
}

module "bootstrap" {
  source          = "./modules/lambda-swift5-bootstrap"
  executable_file = "${module.extract_executable.output_file}"
}

module "api" {
  source           = "./modules/lambda-http-api"
  name             = "swift_demo"
  stage_name       = "prod"
  account_id       = "${data.aws_caller_identity.current.account_id}"
  code_filename    = "${module.bootstrap.zip_file}"
  handler          = "com.github.kperson.api.LambdaAPI"
  role             = "${data.template_file.role_completion.rendered}"
  env              = "${local.app_envs}"
  runtime          = "provided"
  layers           = "${local.layers}"
  source_code_hash = "${module.bootstrap.zip_file_hash}"
}


output "api_endpoint" {
  value = "${module.api.api_endpoint}"
}
