terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "~> 3.0.1"
    }
  }
}

# env
# VAULT_ADDR
# VAULT_TOKEN
provider "vault" {}

resource "vault_identity_oidc" "server" {}

resource "vault_identity_oidc_key" "key" {
  name      = "key"
  algorithm = "RS256"
}

resource "vault_identity_oidc_role" "role" {
  name = "role"
  key  = vault_identity_oidc_key.key.name
}

resource "vault_identity_oidc_key_allowed_client_id" "role" {
  key_name          = vault_identity_oidc_key.key.name
  allowed_client_id = vault_identity_oidc_role.role.client_id
}
