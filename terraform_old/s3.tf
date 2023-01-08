resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket        = var.app_s3_codepipeline_artifacts
  force_destroy = true

  tags = {
    Name = "suitme-codepipeline-artifacts"
  }
}
