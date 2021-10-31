terraform {
  required_providers {
    okta = {
      source = "okta/okta"
      version = "~> 3.14"
    }
    vault = {
      source = "hashicorp/vault"
      version = "~> 2.24"
    }
  }
}

variable "okta_org_name" {
  type = string
}

variable "okta_base_url" {
  type = string
}

# env
# VAULT_ADDR
# VAULT_TOKEN
provider "vault" {}


# OKTA_ORG_NAME 
# OKTA_BASE_URL
# OKTA_API_TOKEN 
provider "okta" { 
  org_name = var.okta_org_name
  base_url = var.okta_base_url
}

locals {
  okta_domain = "${var.okta_org_name}.${var.okta_base_url}"
}

resource "okta_group" "vault_admin" {
  name        = "Vault Admin"
  description = "Vault UI Administrators"
}


resource "vault_policy" "full_admin" {
  name = "full-admin"
  policy = file("${path.module}/policies/admin.hcl") 
}

resource "okta_app_oauth" "vault" {
  label                      = "vault"
  type                       = "web"
  grant_types                = ["authorization_code"]
  login_scopes = [
    "email"
  ]
  redirect_uris              = [
    "http://127.0.0.1:8200/ui/vault/auth/jwt/okta/callback",
    "http://127.0.0.1:8250/oidc/callback",
    "http://localhost:8200/ui/vault/auth/jwt/okta/callback",
    "http://localhost:8250/oidc/callback",
  ]
  response_types = ["code"]

  lifecycle {
   ignore_changes = [
     groups,
     users,
   ]
  }
}

resource "okta_app_group_assignment" "example" {
  app_id   = okta_app_oauth.vault.id
  group_id = okta_group.vault_admin.id
}

resource "vault_jwt_auth_backend" "okta" {
    description         = "Okta auth backend"
    path                = "okta"
    type                = "oidc"
    oidc_discovery_url  = "https://${local.okta_domain}"
    
    # TODO make this into a vault k-v
    oidc_client_id      = okta_app_oauth.vault.client_id
    oidc_client_secret  = okta_app_oauth.vault.client_secret

    default_role = "default"

    bound_issuer = "api://default"
    tune {
      default_lease_ttl = "8h"
      listing_visibility = "unauth"
      max_lease_ttl = "8h"
      token_type = "default-service"
    }
}

resource "vault_jwt_auth_backend_role" "default_role" {
  backend         = vault_jwt_auth_backend.okta.path
  role_name       = "default"
  token_policies  = [vault_policy.full_admin.name]

  user_claim = "sub"
  role_type = "oidc"
  allowed_redirect_uris = [
    "http://127.0.0.1:8250/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]
}
