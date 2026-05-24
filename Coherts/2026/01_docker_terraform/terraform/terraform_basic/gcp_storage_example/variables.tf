variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = "project-78e28b0c-0612-4b66-baf"
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "bucket_location" {
  description = "GCS bucket location"
  type        = string
  default     = "US"
}

variable "bucket_prefix" {
  description = "Bucket name prefix (must be globally unique after suffix is added)"
  type        = string
  default     = "homework-pipeline"
}
