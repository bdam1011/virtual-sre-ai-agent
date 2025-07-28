variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "cloud-sre-poc-465509"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-east1"
}

variable "gcp_credentials_file" {
  description = "Path to GCP credentials json file"
  type        = string
  default     = "../cloud-sre-poc-465509-ffba818f2e1c.json"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "tracing-gke-cluster"
}

variable "graylog_admin_password" {
  description = "Graylog admin password (SHA2 hash)"
  type        = string
  sensitive   = true
  default     = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918" # admin
}

variable "graylog_password_secret" {
  description = "Graylog password secret"
  type        = string
  sensitive   = true
  default     = "somepasswordpepper"
}
