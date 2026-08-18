variable "name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "service_principals" {
  type = list(string)
}

variable "managed_policy_arns" {
  type    = list(string)
  default = []
}
