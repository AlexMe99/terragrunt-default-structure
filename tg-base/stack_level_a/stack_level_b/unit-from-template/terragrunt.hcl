include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "unit_template" {
  path = "${get_terragrunt_dir()}/../../../_templates/unit.hcl"
}
