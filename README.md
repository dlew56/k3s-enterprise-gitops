# K3s Enterprise Cluster Setup Guide

This document outlines the recommended steps and best practices for setting up an enterprise-grade Kubernetes (K3s) cluster on Proxmox LXC, including centralized authentication, GitOps, ingress, and supporting services.

---

## **Setup Order & Rationale**

1. **ArgoCD** – GitOps management for all cluster resources.
2. **Keycloak** – Central Identity Provider (IdP) for SSO (SAML/OAuth2).
3. **NGINX Ingress Controller** – Reverse proxy for all HTTPS sites, integrates with Keycloak for authentication.
4. **Web Applications** – Deployed and managed via ArgoCD, secured by Keycloak SSO.
5. **Supporting Services** – Monitoring, logging, cert management, backup, policy enforcement, etc.

---

## **1. ArgoCD Installation (with Helm)**

### **Add the ArgoCD Helm Repository**
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

### **Create Namespace for ArgoCD**
```bash
kubectl create namespace argocd
```

### **Install ArgoCD via Helm**
```bash
helm install argocd argo/argo-cd --namespace argocd
```

*For production, consider using a custom `values.yaml` and upgrading with:*
```bash
helm install argocd argo/argo-cd --namespace argocd -f values.yaml
```

### **Expose the ArgoCD API/UI**
- **Port-forward (quick test):**
  ```bash
  kubectl -n argocd port-forward svc/argocd-server 8080:443
  # Access at https://localhost:8080
  ```
- **Ingress (recommended for production):**
  - Deploy NGINX Ingress Controller first (see below).
  - Create an Ingress resource for ArgoCD (example to be added).

### **Get the Initial Admin Password**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### **Login to ArgoCD UI**
- Username: `admin`
- Password: (from above)
- URL: (from port-forward or Ingress)

---

## **2. Keycloak (Central IdP)**
*To be documented: deploying Keycloak, exposing it, and configuring SAML/OAuth clients.*

---

## **3. NGINX Ingress Controller**
*To be documented: deploying NGINX Ingress, integrating with Keycloak for SSO, TLS setup.*

---

## **4. Web Applications**
*To be documented: deploying apps via ArgoCD, securing with Keycloak SSO.*

---

## **5. Supporting Services (Recommended)**
- **cert-manager:** Automated TLS certificates
- **External-DNS:** DNS automation
- **Prometheus & Grafana:** Monitoring
- **Loki/ELK:** Logging
- **Velero:** Backup
- **Kubernetes Dashboard:** (secured via SSO)
- **Network Policies:** Calico/Cilium
- **OPA/Gatekeeper:** Policy enforcement
- **Harbor:** Private registry (optional)

---

## **References**
- [ArgoCD Docs](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Keycloak Helm](https://artifacthub.io/packages/helm/bitnami/keycloak)
- [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager](https://cert-manager.io/)
- [Prometheus Helm](https://github.com/prometheus-community/helm-charts)
- [Loki](https://grafana.com/oss/loki/)
- [Velero](https://velero.io/) 