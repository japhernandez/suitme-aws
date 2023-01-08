variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "alb-sg" {
  type    = string
  default = "alb-security-group"
}

variable "alb" {
  type    = string
  default = "app-alb"
}

variable "repository" {
  type    = string
  default = "suitme"
}

variable "task_execution_role" {
  type    = string
  default = "app-task-execution-role"
}

variable "task_execution_policy_attachment" {
  type    = string
  default = "app-task-execution-policy-attachment"
}

variable "cluster" {
  type    = string
  default = "app-cluster"
}

variable "task_security_group" {
  type    = string
  default = "app-task-security-group"
}

variable "app" {
  type    = string
  default = "app"
}

variable "app_target_group" {
  type    = string
  default = "app-target-group"
}

variable "iam_role_app_codebuild" {
  type    = string
  default = "app-codebuild"
}

variable "app_s3_codepipeline_artifacts" {
  type    = string
  default = "suitme-artifacts"
}

variable "iam_role_app_codepipeline" {
  type    = string
  default = "app-codepipeline"
}

variable "iam_role_app_codepipeline_policy" {
  type    = string
  default = "app-codepipeline-policy"
}

variable "github_app_connection" {
  type    = string
  default = "github-app-connection"
}

variable "app_pipeline" {
  type    = string
  default = "app-pipeline"
}
