variable "name" {
  type    = string
  default = "demo"
}

output "id" {
  value = var.name
}
