data "azurerm_client_config" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags,
  )
}

resource "azurerm_resource_group" "main" {
  name     = coalesce(var.resource_group_name, "${local.name_prefix}-rg")
  location = var.location
  tags     = local.common_tags
}

# Generated once, written straight into Key Vault. The value is never rendered
# in plain text in the config, only referenced.
resource "random_password" "postgres" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# User-assigned identity for the app to read secrets. Created independently of
# the Container App so the Key Vault access policy has no circular dependency.
resource "azurerm_user_assigned_identity" "app" {
  name                = "${local.name_prefix}-app-id"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "${local.name_prefix}-psql"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = var.postgres_version
  administrator_login           = var.postgres_admin_username
  administrator_password        = random_password.postgres.result
  sku_name                      = var.postgres_sku_name
  storage_mb                    = var.postgres_storage_mb
  public_network_access_enabled = true
  zone                          = "1"
  tags                          = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_key_vault" "main" {
  name                = "${local.name_prefix}-kv"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.common_tags

  # Deployer: manage secrets during apply.
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }

  # App identity: read-only access to the secrets it consumes.
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = azurerm_user_assigned_identity.app.principal_id
    secret_permissions = ["Get", "List"]
  }
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = random_password.postgres.result
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_container_app_environment" "main" {
  name                = "${local.name_prefix}-env"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_container_app" "app" {
  name                         = "${local.name_prefix}-app"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  # DB password is pulled from Key Vault at runtime using the app identity.
  secret {
    name                = "postgres-password"
    identity            = azurerm_user_assigned_identity.app.id
    key_vault_secret_id = azurerm_key_vault_secret.postgres_password.versionless_id
  }

  ingress {
    external_enabled = true
    target_port      = var.app_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "test-backend"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.app.name
      }
      env {
        name  = "DB_USER_NAME"
        value = var.postgres_admin_username
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "postgres-password"
      }
      # Azure PostgreSQL Flexible Server requires TLS; appended to the JDBC URL.
      env {
        name  = "DB_OPTIONS"
        value = "?sslmode=require"
      }
    }
  }
}
