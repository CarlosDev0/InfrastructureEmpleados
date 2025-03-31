terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

# Network for communication between services
resource "docker_network" "app_network" {
  name = "app_network"
}

resource "docker_volume" "sqlserver_data" {
  name = "sqlserver_data"
}

resource "docker_container" "sqlserver" {
  name    = "sqlserver"
  image   = "mcr.microsoft.com/azure-sql-edge"
  restart = "unless-stopped"

  env = [
    "SA_PASSWORD=YourStrong!Passw0rd",
    "ACCEPT_EULA=Y",
    "MSSQL_PID=Developer",            # Specifies the SQL Server edition
    "MSSQL_USER=sa",                  # Define SA user explicitly
    "MSSQL_PASSWORD=YourStrong!Passw0rd",
    "MSSQL_DATABASE=ecdatabase"    # Define the database name
  ]
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 1433
    external = 1433
  }

  volumes {
    volume_name    = docker_volume.sqlserver_data.name
    container_path = "/var/opt/mssql"
  }
  depends_on = [docker_volume.sqlserver_data]
}

# Backend API Container
resource "docker_image" "backend" {
  name = "apiempleados"
  build {
    context    = "../../../Api/DotnetApi01/ApiEmpleados/ApiEmpleados" # Adjust path to your C# API folder
    dockerfile = "Dockerfile"
  }
}


resource "docker_container" "backend" {
  name  = "backend_container"
  image = docker_image.backend.image_id
  
  networks_advanced {
    name = docker_network.app_network.name
  }
  env = [
    "ASPNETCORE_ENVIRONMENT=Production",
    "ConnectionStrings__DefaultConnection=Server=sqlserver,1433;Initial Catalog=ecdatabase;Persist Security Info=False;User ID=sa;Password=YourStrong!Passw0rd;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;",
  ]
  ports {
    internal = 5000
    external = 5000
  }
}

# Frontend Container
resource "docker_image" "frontend" {
  name = "dashboard_image"
  build {
    context    = "../../../Next/Dashboard" # Adjust path to your Next.js frontend folder
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "frontend" {
  name  = "dashboard"
  image = docker_image.frontend.image_id
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 3000
    external = 3000
  }
  depends_on = [docker_container.backend]
}