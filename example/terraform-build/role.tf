# Task Role
data "aws_iam_policy_document" "tasks_assume_role_policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "tasks_role_policy_doc" {

  statement {
    actions = [
      "logs:*",
    ]

    resources = [
      "*",
    ]
  }

}

resource "aws_iam_policy" "tasks_policy" {
  name   = "swift_demo_tasks_assume_policy"
  policy = "${data.aws_iam_policy_document.tasks_role_policy_doc.json}"
}

resource "aws_iam_role" "tasks_role" {
  name               = "swift_demo_tasks_role"
  assume_role_policy = "${data.aws_iam_policy_document.tasks_assume_role_policy_doc.json}"
}

resource "aws_iam_role_policy_attachment" "tasks_base_policy" {
  role       = "${aws_iam_role.tasks_role.name}"
  policy_arn = "${aws_iam_policy.tasks_policy.arn}"
}

#hack, we need to wait until the attachement is complete
data "template_file" "role_completion" {
  depends_on = ["aws_iam_role_policy_attachment.tasks_base_policy"]
  template   = "$${arn}"

  vars = {
    arn = "${aws_iam_role.tasks_role.arn}"
  }
}
