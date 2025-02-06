variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "potions"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "ably_account_token" {
  description = "Ably account token for authentication"
  type        = string
  sensitive   = true
}

variable "supabase_access_token" {
  description = "Supabase access token"
  type        = string
  sensitive   = true
}

variable "supabase_db_pass" {
  description = "Supabase database password"
  type        = string
  sensitive   = true
}

variable "supabase_organization_id" {
  description = "Supabase organization ID"
  type        = string
}

variable "render_api_key" {
  description = "Render API key"
  type        = string
  sensitive   = true
}

variable "render_owner_id" {
  description = "Render owner ID"
  type        = string
}

variable "github_token" {
  description = "GitHub token"
  type        = string
  sensitive   = true
}

variable "organization_name" {
    description = "Organization name"
    type = string
    default = "potions-369"
  }

  variable "workspace_name" {
    description = "Workspace name"
    type = string
    default = "potions-infra"
  }

  variable "owner" {
    description = "Owner id"
    type = string
    default = "AlfredMadere"
  }

  variable "repository_url" {
    description = "Link to github repository"
    type = string
    default = "https://github.com/AlfredMadere/potions-testing"
  }

  variable "repository_full_name" {
    description: "Name of repository"
    type = string
    default = "AlfredMadere/potions-testing"
  }
