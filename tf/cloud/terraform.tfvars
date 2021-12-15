project_name            = "hock-appl"
app_prod_database_name  = "hockeydbprod"
app_test_database_name  = "hockeydbtest"
sonarqube_database_name = "sonarqubedb"
eks_cluster_name        = "hock-cl"
efs_throughput          = "125"

tags = {
  Owner       = "SeregaDevOps"
  Environment = "DemoStend"
}

ecr_repositories = ["backend-app", "init", "get-static"]
