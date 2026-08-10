variable "project_id" { type = string }
variable "region" { type = string, default = "asia-northeast3" }
variable "environment" { type = string, default = "dev" }
variable "network_cidr" { type = string, default = "10.20.0.0/20" }

variable "enable_gke" { type = bool, default = true }
variable "enable_cloud_sql" { type = bool, default = false }
variable "enable_composer" { type = bool, default = false }

variable "db_version" { type = string, default = "POSTGRES_16" }
variable "db_tier" { type = string, default = "db-custom-2-7680" }

variable "composer_image_version" {
  type        = string
  description = "Use an explicitly supported Managed Airflow/Composer 3 image version."
  default     = "composer-3-airflow-2.11.1-build.11"
}
