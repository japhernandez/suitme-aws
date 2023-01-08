resource "aws_codepipeline" "pipeline" {
  name     = var.app_pipeline
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github_app.arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "app-build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["app_build_output"]
      version          = 1

      configuration = {
        ProjectName = aws_codebuild_project.app.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "app-deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "ECS"
      version  = 1

      configuration = {
        ClusterName = aws_ecs_cluster.cluster.id
        ServiceName = aws_ecs_service.app.id
        FileName    = "imagedefinitions.json"
      }

      input_artifacts = ["app_build_output"]
    }
  }

}
