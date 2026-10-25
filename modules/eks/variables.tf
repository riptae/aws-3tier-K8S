variable "name" { type = string }

variable "subnet_ids" { type = list(string) }

variable "admin_cidrs" { type = list(string) }

variable "admin_principal_arn" { type = string }

variable "tags" { type = map(string) }
