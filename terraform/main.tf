locals {
  prefix = "managed-${var.environment}"
  services = toset([
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com"
  ])
}

resource "google_project_service" "apis" {
  for_each           = local.services
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "main" {
  name                    = "${local.prefix}-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "main" {
  name                     = "${local.prefix}-subnet"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.network_cidr
  private_ip_google_access = true
}

resource "google_artifact_registry_repository" "apps" {
  location      = var.region
  repository_id = "app-images"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository" "models" {
  location      = var.region
  repository_id = "model-images"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository" "python" {
  location      = var.region
  repository_id = "python-packages"
  format        = "PYTHON"
  description   = "Optional internal Python packages for Composer/shared libraries"
}

resource "google_storage_bucket" "notebooks" {
  name                        = "${var.project_id}-${local.prefix}-notebooks"
  location                    = var.region
  uniform_bucket_level_access = true
  versioning { enabled = true }
}

resource "google_container_cluster" "autopilot" {
  count               = var.enable_gke ? 1 : 0
  name                = "gke-ai-${var.environment}"
  location            = var.region
  enable_autopilot    = true
  network             = google_compute_network.main.id
  subnetwork          = google_compute_subnetwork.main.id

    networking_mode = "VPC_NATIVE"

  ip_allocation_policy {}

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  deletion_protection = false

  release_channel { channel = "REGULAR" }
}

resource "google_compute_global_address" "private_service_range" {
  count         = var.enable_cloud_sql ? 1 : 0
  name          = "${local.prefix}-private-service-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.enable_cloud_sql ? 1 : 0
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range[0].name]
}

resource "google_sql_database_instance" "metadata" {
  count               = var.enable_cloud_sql ? 1 : 0
  name                = "${local.prefix}-metadata-db"
  region              = var.region
  database_version    = var.db_version
  deletion_protection = false

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_service_account" "composer" {
  count        = var.enable_composer ? 1 : 0
  account_id   = "composer-${var.environment}"
  display_name = "Managed Airflow service account"
}

resource "google_project_iam_member" "composer_worker" {
  count   = var.enable_composer ? 1 : 0
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer[0].email}"
}

resource "google_composer_environment" "composer" {
  provider = google-beta
  count    = var.enable_composer ? 1 : 0
  name     = "managed-airflow-${var.environment}"
  region   = var.region

  config {
    software_config {
      image_version = var.composer_image_version
    }
    node_config {
      service_account = google_service_account.composer[0].email
    }
  }

  depends_on = [google_project_iam_member.composer_worker]
}
