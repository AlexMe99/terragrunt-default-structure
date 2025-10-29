# TODO define remote state for azure
# remote_state {
#   backend = "s3"
#   config = {
#     bucket         = "my-tofu-state"
#     key            = "${path_relative_to_include()}/tofu.tfstate" # explain for the directory hierachy
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "my-lock-table"
#   }
# }

generate "provider" {
  path      = "provider.tf"
  if_exists = "skip"
  contents  = <<EOF
terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "=3.2.4"
    }
  }
}

provider null {
}
EOF
}
