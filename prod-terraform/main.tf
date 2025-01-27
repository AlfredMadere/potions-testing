terraform {
  cloud {

    organization = "potions-369"

    workspaces {
      name = "potion-infra"
    }
  }
  required_providers {
    ably = {
      source = "ably/ably"
    }
    supabase = {
      source = "supabase/supabase"
    }
  }


}


# Configure Ably provider
provider "ably" {
  token = var.ably_account_token
}

# Configure Supabase provider
provider "supabase" {
  access_token = var.supabase_access_token
}

# Create Ably app
resource "ably_app" "potions" {
  name     = "${var.project_name}-${var.environment}"
  status   = "enabled"
  tls_only = false
}

# Create root API key with all capabilities
resource "ably_api_key" "root" {
  app_id = ably_app.potions.id
  name   = "root-key"
  capabilities = {
    "[*]*" = ["subscribe", "publish", "presence", "history", "push-subscribe", "push-admin", "channel-metadata", "privileged-headers"] # FIXME: root has every capability on every resource
  }
}

# Create Supabase project
resource "supabase_project" "potions" {
  organization_id   = var.supabase_organization_id
  name              = "${var.project_name}-${var.environment}"
  database_password = var.supabase_db_pass
  region            = "us-west-1"

  lifecycle {
    ignore_changes = [
      database_password,
      instance_size,
    ]
  }
}

resource "null_resource" "poll_project_status" {
  depends_on = [supabase_project.potions]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      TIMEOUT=300   # 5 minutes
      INTERVAL=15   # check every 15 seconds
      ELAPSED=0

      while [ $ELAPSED -lt $TIMEOUT ]; do
        STATUS=$(curl -s -H "Authorization: Bearer ${var.supabase_access_token}" \
          https://api.supabase.io/v1/projects/${supabase_project.potions.id} \
          | jq -r '.status')

        if [ "$STATUS" == "ACTIVE_HEALTHY" ]; then
          echo "Project status is ACTIVE_HEALTHY. Continuing..."
          exit 0
        fi

        echo "Current project status is: $STATUS. Waiting..."
        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
      done

      echo "Project status did not reach ACTIVE_HEALTHY within $TIMEOUT seconds."
      exit 1
    EOT
  }
}

# Get pooler connection string
data "supabase_pooler" "main" {
  depends_on  = [null_resource.poll_project_status]
  project_ref = supabase_project.potions.id
}

locals {
  db_connection_string = replace(data.supabase_pooler.main.url["transaction"], "[YOUR-PASSWORD]", var.supabase_db_pass)
}


# Execute database setup SQL
resource "null_resource" "database_setup" {
  depends_on = [data.supabase_pooler.main]

  provisioner "local-exec" {
    # Force Terraform to run under bash
    interpreter = ["bash", "-c"]

    command = <<-EOT
      psql -f ../sql/setup.sql "${local.db_connection_string}"
    EOT
  }
}

# Insert test world
resource "null_resource" "insert_test_world" {
  depends_on = [null_resource.database_setup]

  provisioner "local-exec" {
    # Force Terraform to run under bash
    interpreter = ["bash", "-c"]

    command = <<-EOT
      psql "${local.db_connection_string}" -c "INSERT INTO worlds (world_id, ably_api_key) VALUES ('test-world', '${ably_api_key.root.key}')"
    EOT
  }
}

data "supabase_apikeys" "dev" {
  project_ref = supabase_project.potions.id
}