resource "null_resource" "example" {
  provisioner "local-exec" {
    command = "echo \"${var.global_text} | ${var.stack_level_a_text} | ${var.stack_level_b_text} | ${var.unit_text}\""
  }
}
