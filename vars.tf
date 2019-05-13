##
## AWS API credentials
##

variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "region" {
  default = "us-east-2"
}

##
## FreeNAS-backup specific variables
##

variable "name_suffix" {
  description = "This is your unique name suffix for your created resources."
  type        = "string"
}

variable "standard_ia_transition" {
  description = "The amount in days before an uploaded object is transferred to standard IA storage"
  default     = 30
}

variable "noncurrent_version_transition" {
  description = "The amount in days before a nonocurrent version object is transferred to glacier"
  default     = 90
}
