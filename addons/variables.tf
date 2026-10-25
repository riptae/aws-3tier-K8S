variable "infrastructure_state_path" {
  type        = string
  default     = "../terraform/terraform.tfstate"
  description = "Infrastructure local state path, relative to the addons working directory."
}
