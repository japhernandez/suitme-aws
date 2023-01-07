resource "aws_codestarconnections_connection" "github_app" {
  name          = var.github_app_connection
  provider_type = "GitHub"
}
