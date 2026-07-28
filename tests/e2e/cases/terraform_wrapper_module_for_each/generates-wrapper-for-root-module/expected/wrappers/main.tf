module "wrapper" {
  source = "../"

  for_each = var.items

  name = try(each.value.name, var.defaults.name)
}
