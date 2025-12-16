# Install cert-manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.3"
  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

# Deploy Let's Encrypt certificate issuers for production and staging
resource "helm_release" "cert_manager_issuers" {
  name       = "cert-manager-issuers"
  repository = "https://charts.adfinis.com"
  chart      = "cert-manager-issuers"
  version    = "0.3.0"
  namespace  = "cert-manager"

  values = [<<-EOF
    _1: &email ${var.letsencrypt_email}
    _2: &solvers
    - http01:
        ingress:
          class: nginx

    clusterIssuers:
    - name: letsencrypt-prod
      spec:
        acme:
          email: *email
          server: https://acme-v02.api.letsencrypt.org/directory
          privateKeySecretRef:
            name: letsencrypt-prod-account-key
          solvers: *solvers
    - name: letsencrypt-staging
      spec:
        acme:
          email: *email
          server: https://acme-staging-v02.api.letsencrypt.org/directory
          privateKeySecretRef:
            name: letsencrypt-staging-account-key
          solvers: *solvers
    EOF
  ]

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    helm_release.cert_manager
  ]
}

