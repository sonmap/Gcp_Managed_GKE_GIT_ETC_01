project_id   = "dev-com-334508"
region       = "asia-northeast3"
environment  = "dev"
network_cidr = "10.20.0.0/20"

enable_gke       = true
enable_cloud_sql = false
enable_composer  = true

# Before enabling Composer, verify a currently supported exact image version.
composer_image_version = "composer-3-airflow-2.11.1-build.11"
