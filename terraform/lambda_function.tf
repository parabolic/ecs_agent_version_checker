resource "aws_lambda_function" "ecs_agent_updater" {
  runtime          = "go1.x"
  description      = "Lambda function for updating outdated ecs agents."
  timeout          = "10"
  depends_on       = ["aws_s3_bucket_object.upload_zipped_function_to_s3"]
  function_name    = "${local.environment}-${local.application_name}"
  s3_key           = "${local.binary_file_name}.zip"
  s3_bucket        = "${aws_s3_bucket.go_lambda_function.id}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "${local.binary_file_name}"
  source_code_hash = "${base64sha256(file("${local.binary_file_path}"))}"
  kms_key_arn      = "${aws_kms_key.kms_for_lambda.arn}"

  environment {
    variables = {
      SLACK_WEBHOOK_ENDPOINT = "${var.slack_webhook_endpoint}"
      UPDATE_ECS_AGENT       = "${var.update_ecs_agent}"
    }
  }

  tags {
    Name        = "${local.environment}-${local.application_name}"
    environment = "${local.environment}"
    created_by  = "terraform"
  }
}

resource "aws_lambda_permission" "allow_lambda_scheduled_events" {
  source_arn    = "${aws_cloudwatch_event_rule.ecs_agent_updater.arn}"
  function_name = "${aws_lambda_function.ecs_agent_updater.function_name}"
  statement_id  = "AllowScheduledExecution"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
}
