terraform {
  cloud {
    organization = "YOUR-ORG-NAME"  # Replace with your Terraform Cloud org
    workspaces {
      name = "terraform-learning"
    }
  }
  
  required_providers {
    google = { source = "hashicorp/google", version = ">= 5.0.0" }
  }
}

provider "google" {
  project = var.project_id  # You'll need to set this
  region  = "us-central1"
  zone    = "us-central1-a"
}

#################
# Variables
#################
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  # Set via environment variable: export TF_VAR_project_id="your-project-id"
}

##########
# Network
##########
resource "google_compute_network" "main" {
  name                    = "vpc-main"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app" {
  name          = "subnet-app"
  network       = google_compute_network.main.id
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
}

#################
# Firewall Rules
#################
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]
}

#####################
# Compute Instance
#####################
resource "google_compute_instance" "app" {
  name         = "vm-app"
  machine_type = "e2-micro"  # Free tier eligible!
  zone         = "us-central1-a"

  tags = ["web-server", "ssh-enabled"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10  # Minimum size, keeps costs down
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app.id

    access_config {
      # This creates an ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Hello from Terraform on GCP!</h1>" > /var/www/html/index.html
    systemctl restart nginx
  EOF

  # This allows the VM to be preemptible (cheaper but can be terminated)
  # Comment out for more stability
  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

##########
# Outputs
##########
output "public_ip" {
  value       = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
  description = "Public IP address of the app VM"
}

output "ssh_command" {
  value       = "gcloud compute ssh ubuntu@vm-app --zone=us-central1-a"
  description = "SSH command using gcloud CLI"
}

output "ssh_command_direct" {
  value       = "ssh ubuntu@${google_compute_instance.app.network_interface[0].access_config[0].nat_ip}"
  description = "Direct SSH command"
}

output "web_url" {
  value       = "http://${google_compute_instance.app.network_interface[0].access_config[0].nat_ip}"
  description = "URL to access the web server"
}