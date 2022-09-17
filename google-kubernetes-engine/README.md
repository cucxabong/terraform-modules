# Terraform Kubernetes Engine Module with Optional CSI Secret Store and ArgoCD

## This module provide a way to simplify creating Google Cloud Platform Kubernetes Engine with Workload Identity enabled and optionally deploy CSI Secret Store with GCP Secret Manager provider and GitOps operator ArgoCD. The resources that this module will create are:

- Provisioing a GKE cluster
- Create node pools and attached to cluster
- Option to enable [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- Install [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) and [Google Secret Manager Provider](https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp)
- Install [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) & configure it using secret values from GCP Secret Manager

## Usage

```hcl

locals {
  argocd_namespace = "argocd"
  project_id       = "example-gcp-project-id"
  region           = "asia-southeast1"

  mapping = {
    argocd = {
      gcp_roles = [
        "roles/secretmanager.secretAccessor"
      ]
      kubernetes_namespace  = local.argocd_namespace
      create_sa_key         = false
      export_sa_private_key = false
    }
  }
}

data "google_client_config" "default" {}

provider "google" {
  project = local.project_id
  region  = local.region
}

provider "kubectl" {
  host                   = "https://${module.example.endpoint}"
  cluster_ca_certificate = base64decode(module.example.ca_certificate)
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.example.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.example.ca_certificate)
  }
}


terraform {
  experiments = [module_variable_optional_attrs]

  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

module "service_accounts" {
  source                          = "github.com/cucxabong/terraform-modules?ref=main//google-iam-service-account"
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


module "example" {
  source                   = "github.com/cucxabong/terraform-modules?ref=main//google-kubernetes-engine"
  cluster_name             = "example-gke"
  ip_range_nodes           = "192.168.0.0/24"
  ip_range_pods            = "10.18.0.0/16"
  ip_range_services        = "10.19.0.0/16"
  networking_mode          = "VPC_NATIVE"
  remove_default_node_pool = true
  regional                 = true
  region                   = local.region
  disable_workload_log     = true
  release_channel          = "UNSPECIFIED"

  node_pools = [
    {
      name         = "n2-standard-16-pool"
      autoscaling  = true
      min_count    = 1
      max_count    = 3
      image_type   = "COS_CONTAINERD"
      machine_type = "n2-standard-16"
      auto_upgrade = false
      auto_repair  = true
    }
  ]

  csi_secrets_store = {
    enabled            = true
    enable_sync_secret = true
    providers = {
      gcp = {
        enabled = true
      }
    }
  }

  argocd = {
    enabled          = true
    version          = "5.4.0"
    repository       = "https://argoproj.github.io/argo-helm"
    namespace        = local.argocd_namespace
    create_namespace = true
    values = [
      <<-EOT
      server:
        rbacConfig:
          scopes: '[groups, email]'
          policy.default: role:readonly
        config:
          url: "https://public-argocd.example.com"
          users.anonymous.enabled: "false"
          oidc.config: |
            name: Google
            issuer: https://accounts.google.com
            clientID: xxxx.apps.googleusercontent.com
            clientSecret: $argocd-extra-secrets:oidc.google.clientSecret
            requestedScopes: ["openid", "profile", "email"]
        volumeMounts:
          - mountPath: /extra-secrets-dummy
            name: argocd-extra-secrets
            readOnly: true
        volumes:
          - csi:
              driver: secrets-store.csi.k8s.io
              readOnly: true
              volumeAttributes:
                secretProviderClass: argocd-extra-secrets
            name: argocd-extra-secrets
        extraArgs:
          - --insecure
        serviceAccount:
          create: true
          name: argocd
          annotations:
            iam.gke.io/gcp-service-account: ${module.service_accounts["argocd"].google_service_account_email}
          automountServiceAccountToken: true
        ingress:
          enabled: true
          ingressClassName: "nginx"
          hosts:
            - public-argocd.example.com
      controller:
        args:
          appResyncPeriod: "30"
        serviceAccount:
          name: argocd-application-controller
          annotations:
            iam.gke.io/gcp-service-account: ${module.service_accounts["argocd"].google_service_account_email}
          automountServiceAccountToken: true
      extraObjects:
        - apiVersion: secrets-store.csi.x-k8s.io/v1
          kind: SecretProviderClass
          metadata:
            name: argocd-extra-secrets
          spec:
            parameters:
              secrets: |
                - resourceName: "projects/example-gcp-project-id/secrets/argocd-oidc-client-secret/versions/1"
                  fileName: "oidc.google.clientSecret"
                - resourceName: "projects/example-gcp-project-id/secrets/argocd-ssh-private-key/versions/1"
                  fileName: "sshPrivateKey"
                - resourceName: "projects/example-gcp-project-id/secrets/argocd-repo-type-git/versions/1"
                  fileName: "credsTypeGit"
                - resourceName: "projects/example-gcp-project-id/secrets/argocd-repo-url/versions/1"
                  fileName: "ConfigUrl"
            provider: gcp
            secretObjects:
              - secretName: argocd-repo
                data:
                  - key: sshPrivateKey
                    objectName: sshPrivateKey
                  - key: type
                    objectName: credsTypeGit
                  - key: url
                    objectName: ConfigUrl
                type: Opaque
                labels:
                  argocd.argoproj.io/secret-type: repository
              - data:
                  - key: oidc.google.clientSecret
                    objectName: oidc.google.clientSecret
                secretName: argocd-extra-secrets
                type: Opaque
                labels:
                  app.kubernetes.io/part-of: argocd
EOT
    ]
  }
}
```
