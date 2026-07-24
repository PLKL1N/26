variable "project" {
  type = string
}

variable "repo_names" {
  description = "Application names to create ECR repositories for"
  type        = list(string)
  default     = ["user", "product", "stress"]
}

variable "image_retention_count" {
  description = "Number of images to keep per repository (cost optimization)"
  type        = number
  default     = 10
}
