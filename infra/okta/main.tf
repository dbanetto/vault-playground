terraform {
  required_providers {
    okta = {
      source = "okta/okta"
      version = "~> 3.14"
    }
  }
}

# OKTA_ORG_NAME 
# OKTA_BASE_URL
# OKTA_API_TOKEN 
provider "okta" { }
