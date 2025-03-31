output "container_id" {
  description = "ID of the Docker container backend"
  value       = docker_container.backend.id
}

output "image_id" {
  description = "ID of the Docker container frontend"
  value       = docker_container.frontend.id
}
