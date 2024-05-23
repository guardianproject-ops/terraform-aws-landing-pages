variable "bucket_versioning" {
  description = "State of bucket versioning option. Set to \"Enabled\" if required to upgrade a pre-existing instance where an older version of this module had set the option to \"Enabled\" as it is not possible to change this to \"Disabled\" once set."
  type        = string
  default     = "Disabled"
}

variable "choices" {
  description = "The list of URL paths to select from for the A/B test."
  type        = list(string)
}

variable "domain_name" {
  description = "The domain name for the CloudFront distribution."
  type        = string
}

variable "parent_zone_name" {
  description = "The name of the zone that is hosted in Route 53 that contains the domain name for the CloudFront distribution."
  type        = string
}
