variable "executable_file" {
  type = "string"
}

resource "random_string" "tag" {
  length  = 15
  upper   = false
  number  = false
  special = false
  keepers = {
    time = "${timestamp()}"
  }
}
resource "null_resource" "prepare_content" {
  triggers = {
    time = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${random_string.tag.result} && cp ${path.module}/bootstrap ${random_string.tag.result}/ && cp ${var.executable_file} ${random_string.tag.result}/"
  }
}

data "archive_file" "zip" {
  depends_on  = ["null_resource.prepare_content"]
  type        = "zip"
  source_dir  = "${random_string.tag.result}"
  output_path = "${random_string.tag.result}.zip"
}

resource "null_resource" "cleanup" {
  depends_on = ["data.archive_file.zip"]
  provisioner "local-exec" {
    command = "rm -rf ${random_string.tag.result}"
  }
}

output "zip_file" {
  value = "${random_string.tag.result}.zip"
}

output "zip_file_hash" {
  value = "${data.archive_file.zip.output_base64sha256}"
}
