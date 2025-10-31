
locals {
  remote_state = {
    storage_account_name = split("/", path_relative_to_include())[1] # assumes the name to be the first stack level name "stack_level_a"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/tofu.tfstate" # keeps the directory structure from thr root.hcl to the individual terragrunt.hcl
  }
}

# generate "backend" {
#   path      = "backend.tf"
#   if_exists = "skip"
#   contents  = <<EOF
# terraform {
#   backend "azurerm" {
#     storage_account_name = "${local.remote_state.storage_account_name}"
#     container_name       = "${local.remote_state.container_name}"
#     key                  = "${local.remote_state.key}"
#   }
# }
# EOF
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
