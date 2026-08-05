output "resource_group_name" {
  description = "Name of the resource group holding all resources."
  value       = azurerm_resource_group.main.name
}

output "postgres_server_fqdn" {
  description = "Fully qualified hostname of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_name" {
  description = "Name of the application database."
  value       = azurerm_postgresql_flexible_server_database.app.name
}

output "key_vault_uri" {
  description = "Base URI of the Key Vault holding the database credentials."
  value       = azurerm_key_vault.main.vault_uri
}

output "app_url" {
  description = "Public HTTPS URL of the Container App ingress."
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}
