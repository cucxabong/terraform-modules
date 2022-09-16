terraform {
  required_version = ">=0.13"
  experiments      = [module_variable_optional_attrs]

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}
