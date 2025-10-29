include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "stack_level_a" {
  path   = "${get_terragrunt_dir()}/../../stack_level_a.hcl"
  expose = true
}

include "stack_level_b" {
  path   = "${get_terragrunt_dir()}/../stack_level_b.hcl"
  expose = true
}

dependency "another_unit" {
  config_path = "../unit-from-template"

  mock_outputs = {
    message = "I-have-not-run-yet"
  }
}

terraform {
  source = "${get_repo_root()}/local-tf-modules/unit"
}

locals {
  global_vars = yamldecode(file("${get_repo_root()}/global-vars/var-file.yaml"))

  path_to_stack_level_a = "${get_terragrunt_dir()}/../../"
  stack_level_a_dirname = basename(dirname(local.path_to_stack_level_a))
}

inputs = {
  global_text        = local.global_vars.some-vars.i-am-a-string
  stack_level_a_text = "[${local.stack_level_a_dirname}] ${include.stack_level_a.locals.stack_level_a_text}"
  stack_level_b_text = include.stack_level_b.locals.stack_level_b_text
  unit_text          = "I come from a template for the unit level. I have a dependency to unit-from-template, saying: ${dependency.another_unit.outputs.message}"
}
