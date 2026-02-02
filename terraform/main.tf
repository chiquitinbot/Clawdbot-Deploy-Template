terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# Variables
variable "do_token" {
  description = "Digital Ocean API Token"
  type        = string
  sensitive   = true
}

variable "agent_name" {
  description = "Name of the agent (used for droplet name)"
  type        = string
  default     = "my-agent"
}

variable "region" {
  description = "Digital Ocean region"
  type        = string
  default     = "nyc1"
}

variable "size" {
  description = "Droplet size"
  type        = string
  default     = "s-2vcpu-4gb"  # $24/month - good for agents
}

variable "ssh_key_fingerprint" {
  description = "SSH key fingerprint from DO"
  type        = string
}

variable "domain" {
  description = "Domain for the agent (optional)"
  type        = string
  default     = ""
}

variable "anthropic_api_key" {
  description = "Anthropic API Key"
  type        = string
  sensitive   = true
}

variable "discord_token" {
  description = "Discord Bot Token (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "telegram_token" {
  description = "Telegram Bot Token (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

# SSH Key data source
data "digitalocean_ssh_key" "main" {
  name = var.ssh_key_fingerprint
}

# Droplet
resource "digitalocean_droplet" "agent" {
  image    = "ubuntu-24-04-x64"
  name     = "${var.agent_name}-droplet"
  region   = var.region
  size     = var.size
  ssh_keys = [data.digitalocean_ssh_key.main.id]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    agent_name        = var.agent_name
    anthropic_api_key = var.anthropic_api_key
    discord_token     = var.discord_token
    telegram_token    = var.telegram_token
    domain            = var.domain
  })

  tags = ["agent", var.agent_name]
}

# Firewall
resource "digitalocean_firewall" "agent" {
  name = "${var.agent_name}-firewall"

  droplet_ids = [digitalocean_droplet.agent.id]

  # SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTP
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow all outbound
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# DNS Record (if domain provided)
resource "digitalocean_record" "agent" {
  count  = var.domain != "" ? 1 : 0
  domain = var.domain
  type   = "A"
  name   = var.agent_name
  value  = digitalocean_droplet.agent.ipv4_address
  ttl    = 300
}

# Outputs
output "droplet_ip" {
  value       = digitalocean_droplet.agent.ipv4_address
  description = "Public IP of the agent droplet"
}

output "droplet_id" {
  value       = digitalocean_droplet.agent.id
  description = "Droplet ID"
}

output "ssh_command" {
  value       = "ssh root@${digitalocean_droplet.agent.ipv4_address}"
  description = "SSH command to connect"
}

output "agent_url" {
  value       = var.domain != "" ? "https://${var.agent_name}.${var.domain}" : "http://${digitalocean_droplet.agent.ipv4_address}"
  description = "Agent URL"
}
