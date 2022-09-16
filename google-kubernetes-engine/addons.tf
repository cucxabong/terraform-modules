locals {
  # CSI Secret Store
  provider_configured     = var.csi_secrets_store.providers != null ? true : false
  provider_gcp_configured = local.provider_configured ? (var.csi_secrets_store.providers.gcp != null ? true : false) : false
  provider_gcp_enabled    = local.provider_gcp_configured ? (var.csi_secrets_store.providers.gcp.enabled == null ? false : var.csi_secrets_store.providers.gcp.enabled) : false
  provider_gcp_version    = local.provider_gcp_configured ? (var.csi_secrets_store.providers.gcp.version == null ? "1.1.0" : var.csi_secrets_store.providers.gcp.version) : "1.1.0"

  csi_secrets_store_gcp_provider_manifest = {
    for key, value in data.kubectl_file_documents.csi_secrets_store_gcp_provider.manifests : key => value if local.provider_gcp_enabled
  }

  csi_secrets_store_default = {
    namespace    = "kube-system"
    repository   = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
    chart        = "secrets-store-csi-driver"
    release_name = "csi-secrets-store"
  }

  argocd_default = {
    repository        = "https://argoproj.github.io/argo-helm"
    chart_name        = "argo-cd"
    chart_version     = "5.4.0"
    release_name      = "argocd"
    release_namespace = "default"
  }
}

resource "helm_release" "csi_secrets_store" {
  count      = var.csi_secrets_store["enabled"] == true ? 1 : 0
  repository = var.csi_secrets_store["repository"] == null ? local.csi_secrets_store_default.repository : var.csi_secrets_store["repository"]
  name       = var.csi_secrets_store["name"] == null ? "csi-secrets-store" : var.csi_secrets_store["name"]
  chart      = var.csi_secrets_store["chart"] == null ? local.csi_secrets_store_default.chart : var.csi_secrets_store["chart"]
  namespace  = var.csi_secrets_store["namespace"] == null ? local.csi_secrets_store_default.namespace : var.csi_secrets_store["namespace"]
  version    = var.csi_secrets_store["version"]

  set {
    name  = "syncSecret.enabled"
    value = tostring(var.csi_secrets_store["enable_sync_secret"] == null ? false : var.csi_secrets_store["enable_sync_secret"])
  }

  set {
    name  = "enableSecretRotation"
    value = tostring(var.csi_secrets_store["enable_secret_rotation"] == null ? false : var.csi_secrets_store["enable_secret_rotation"])
  }
}

resource "helm_release" "argocd" {
  count            = var.argocd.enabled ? 1 : 0
  repository       = var.argocd.repository == null ? local.argocd_default.repository : var.argocd.repository
  name             = var.argocd.name == null ? local.argocd_default.release_name : var.argocd.name
  chart            = var.argocd.chart == null ? local.argocd_default.chart_name : var.argocd.chart
  version          = var.argocd.version == null ? local.argocd_default.chart_version : var.argocd.version
  values           = var.argocd.values == null ? [] : var.argocd.values
  namespace        = var.argocd.namespace == null ? local.argocd_default.release_namespace : var.argocd.namespace
  create_namespace = true
  depends_on = [
    kubectl_manifest.csi_secrets_store_gcp_provider
  ]
}

data "kubectl_file_documents" "csi_secrets_store_gcp_provider" {
  content = data.http.csi_secrets_store_gcp_provider.body
}

data "http" "csi_secrets_store_gcp_provider" {
  url = "https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/v${local.provider_gcp_version}/deploy/provider-gcp-plugin.yaml"
}

resource "kubectl_manifest" "csi_secrets_store_gcp_provider" {
  for_each  = local.csi_secrets_store_gcp_provider_manifest
  yaml_body = each.value
  depends_on = [
    helm_release.csi_secrets_store
  ]
}
