output "graylog_external_ip" {
  description = "Graylog external IP address"
  value       = google_compute_address.graylog_ip.address
}

output "graylog_web_url" {
  description = "Graylog Web UI URL"
  value       = "http://${google_compute_address.graylog_ip.address}:9000"
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_location" {
  description = "GKE cluster location"
  value       = google_container_cluster.primary.location
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = google_compute_network.tracing_vpc.name
}

output "vpc_subnet_name" {
  description = "VPC subnet name"
  value       = google_compute_subnetwork.tracing_subnet.name
}

output "cloudsql_sa_email" {
  description = "Cloud SQL Proxy Service Account email"
  value       = google_service_account.cloudsql_sa.email
  sensitive   = true
}

output "otel_collector_sa_email" {
  description = "OpenTelemetry Collector Service Account email"
  value       = google_service_account.otel_collector.email
}

output "project_number" {
  description = "GCP project number (for Autopilot Service Account)"
  value       = data.google_project.current.number
}

output "deployment_commands" {
  description = "Commands to deploy Graylog after Terraform completion"
  value = <<-EOT
    # 1. Get GKE credentials:
    gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}
    
    # 2. Deploy Graylog:
    cd ../scripts && ./deploy-graylog.sh
    
    # 3. Access Graylog Web UI:
    # URL: ${google_compute_address.graylog_ip.address}:9000
    # Default login: admin/admin
  EOT
}
