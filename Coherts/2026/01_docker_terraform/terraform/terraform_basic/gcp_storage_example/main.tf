terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.33.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "pipeline_tmp" {
  name                        = "${var.bucket_prefix}-${random_id.suffix.hex}"
  location                    = var.bucket_location
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 3
    }
  }

  labels = {
    purpose = "homework-temp"
  }
}

output "bucket_name" {
  value = google_storage_bucket.pipeline_tmp.name
}
