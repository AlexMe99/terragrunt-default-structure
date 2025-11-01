locals {
  global_vars        = yamldecode(file("${get_repo_root()}/global-vars/var-file.yaml"))
  stack_level_a_vars = read_terragrunt_config(find_in_parent_folders("stack_level_a.hcl"))
  stack_level_b_vars = read_terragrunt_config(find_in_parent_folders("stack_level_b.hcl"))

  path_to_stack_level_a = "${get_terragrunt_dir()}/../../"
  stack_level_a_dirname = basename(dirname(local.path_to_stack_level_a))
}

terraform {
  source = "${get_repo_root()}/local-tf-modules/unit-module"
}

generate "provider_unit" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "=3.2.3"
    }
  }
}

provider null {
}
EOF
}

inputs = {
  global_text        = local.global_vars.some-vars.i-am-a-string
  stack_level_a_text = "[${local.stack_level_a_dirname}] ${local.stack_level_a_vars.locals.stack_level_a_text}"
  stack_level_b_text = local.stack_level_b_vars.locals.stack_level_b_text
  unit_text          = "I come from a template for the unit level."
}
