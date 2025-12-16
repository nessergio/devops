data "external" "bcrypt_password" {
  program = ["python3", "${path.module}/scripts/bcrypt-password.py", var.argocd_admin_pass]
}

# Use the External data source to run 'ssh-keyscan' to retrieve the host key of Azure DevOps Git
data "external" "azure_devops_host_key" {
   program = ["${path.module}/scripts/ssh-keyscan-json.sh", "ssh.dev.azure.com"]
}

data "azuredevops_git_repository" "charts" {
  project_id = var.project_id
  name       = "Charts"
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "8.5.8" # Use latest available version

  create_namespace = true
  replace          = true

  values = [<<-EOF
    global: 
      domain: ${azurerm_public_ip.ingress.fqdn}
    server:
      ingress:
        enabled: true
        path: /argocd
        ingressClassName: nginx
        annotations:
          nginx.ingress.kubernetes.io/ssl-redirect: "true"
          nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
          cert-manager.io/cluster-issuer: letsencrypt-prod
        tls:
          - hosts:
              - ${azurerm_public_ip.ingress.fqdn}
            secretName: master-tls
    configs:
      params:
        server.insecure: true
        server.basehref: /argocd
        server.rootpath: /argocd
      ssh:
        knownHosts: |
          ${indent(8, data.external.azure_devops_host_key.result.host_key)}
      repositories:
        app: 
          type: git
          name: app
          url: ${data.azuredevops_git_repository.charts.web_url}
          username: azureuser
          password: ${var.azdo_pat}
    EOF
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = data.external.bcrypt_password.result.hash
  }

  lifecycle {
    ignore_changes = [set_sensitive]
  }

  recreate_pods     = false
  wait              = true
  timeout           = 600
  dependency_update = true

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    helm_release.nginx_ingresec
  ]
}

resource "helm_release" "argocd-apps" {
  name       = "argocd-apps"
  namespace  = "argocd"
  chart      = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "2.0.2"

  create_namespace = true
  replace          = true

  values = [<<-EOF
    applications:
      root:
        namespace: argocd
        project: default
        source:
          repoURL: ${data.azuredevops_git_repository.charts.web_url}
          targetRevision: master
          path: root
          helm:
            values: |
              acr: "${var.acr_name}.azurecr.io"
              hostname: ${azurerm_public_ip.ingress.fqdn}
              tls_secret_name: master-tls
              charts_repo: ${data.azuredevops_git_repository.charts.web_url}
        destination:
          server: https://kubernetes.default.svc
          namespace: argocd
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
    EOF
  ]

  wait              = true
  timeout           = 600
  dependency_update = true

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

resource "helm_release" "argocd_image_updater" {
  name       = "argocd-image-updater"
  namespace  = "argocd"
  chart      = "argocd-image-updater"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "1.0.2"

  create_namespace = false
  replace          = true

  values = [<<-EOF
    config:
      # Application-based configuration (not CRD-based)
      applicationsAPIKind: "kubernetes"

      registries:
        - name: acr
          api_url: https://${var.acr_name}.azurecr.io
          prefix: ${var.acr_name}.azurecr.io
          default: true
          credentials: env:ACR_CREDENTIALS

    # Log level for debugging
    logLevel: debug

    # Environment variables for ACR authentication
    extraEnv:
      - name: ACR_CREDENTIALS
        value: ${azurerm_container_registry.acr.admin_username}:${azurerm_container_registry.acr.admin_password}
    EOF
  ]

  wait              = true
  timeout           = 600
  dependency_update = true

  depends_on = [
    helm_release.argocd,
    azurerm_kubernetes_cluster.aks,
    azurerm_container_registry.acr
  ]
}

