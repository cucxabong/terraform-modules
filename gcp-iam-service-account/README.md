## Functionality

- Create [Google Cloud Service Account](https://cloud.google.com/iam/docs/service-accounts)
- (Optionally) Create [Service Account Key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) and exporting JSON file to use somewhere
- (Optionally) Binding Google Cloud Service Account with GKE Service Account to support [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)

## Usage

```hcl
locals {
  project_id = "example-id"

  mapping = {
    argocd = {
      gcp_roles = [
        "roles/secretmanager.secretAccessor"
      ]
      kubernetes_namespace  = "argocd"
      create_sa_key         = true
      export_sa_private_key = true
    }
  }
}

module "service_accounts" {
  source                          = "github.com/cucxabong/terraform-modules?ref=main//gcp-iam-service-account"
  project                         = local.project_id
  for_each                        = local.mapping
  gcp_service_account_name        = each.key
  kubernetes_namespace            = lookup(each.value, "kubernetes_namespace", "default")
  kubernetes_service_account_name = lookup(each.value, "kubernetes_service_account_name", each.key)
  gcp_roles                       = lookup(each.value, "gcp_roles", [])
  disable_workload_identity       = lookup(each.value, "disable_workload_identity", false)
  create_sa_key                   = lookup(each.value, "create_sa_key", false)
  export_sa_private_key           = lookup(each.value, "export_sa_private_key", false)
}

```
