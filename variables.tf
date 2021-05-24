/* ---------------------------------------------------------------------------------------------------------------------
  ENVIRONMENT VARIABLES
--------------------------------------------------------------------------------------------------------------------- */

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

/* ---------------------------------------------------------------------------------------------------------------------
  METADATA VARIABLES
--------------------------------------------------------------------------------------------------------------------- */

variable "enabled" {
  description = "Set to false to prevent the module from creating any resources"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace, which may relate to the overarching domain or specific business division"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Describes the environment, e.g. 'PROD', 'staging', 'u', 'dev'"
  type        = string
  default     = ""
}

variable "name" {
  description = "Identifier for a specific application that may consist of many disparate resources"
  type        = string
  default     = ""
}

variable "service" {
  description = "Describes an individual microservice running as part of a larger application"
  type        = string
  default     = ""
}

variable "delimiter" {
  description = "Delimiter to output between 'namespace', 'environment', 'name', 'service' and 'attributes'"
  type        = string
  default     = "-"
}

variable "attributes" {
  description = "Any additional miscellaneous attributes to append to the identifier, e.g. 'cluster', 'worker'"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply, e.g. '{Owner = 'ABC', Product = 'DEF'}'"
  type        = map(string)
  default     = {}
}

/* ---------------------------------------------------------------------------------------------------------------------
  REQUIRED VARIABLES
--------------------------------------------------------------------------------------------------------------------- */

variable "region" {
  description = "Region to provision resources in"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of Availability Zones to create resources in"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type to launch"
  type        = string
}

variable "min_size" {
  description = "The minimum size of the autoscale group"
  type        = number
}

variable "max_size" {
  description = "The maximum size of the autoscale group"
  type        = number
}

variable "desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
  type        = number
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

variable "container_memory" {
  description = "The amount of memory (in MiB) to allow the container to use. This is a hard limit, if the container attempts to exceed the container_memory, the container is killed"
  type        = number
}

/* ---------------------------------------------------------------------------------------------------------------------
  OPTIONAL VARIABLES
--------------------------------------------------------------------------------------------------------------------- */

variable "key_name" {
  description = "The SSH key name that should be used for the instance"
  type        = string
  default     = ""
}
