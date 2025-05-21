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

# K3s Enterprise GitOps

This repository contains the manifests and configuration for managing an enterprise-grade K3s cluster using GitOps principles with ArgoCD.

---

## Repository Structure

```
k3s-enterprise-gitops/
├── cluster/
│   ├── base/
│   │   └── namespaces.yaml         # Namespace definitions
│   └── apps/
│       ├── argocd/
│       │   └── app.yaml           # ArgoCD Application manifest (installs ArgoCD via Helm)
│       ├── keycloak/
│       │   └── app.yaml           # Keycloak Application manifest
│       └── ... (other apps)
├── apps/
│   └── ... (app overlays, e.g. ingress)
└── argo-projects/
    └── ... (optional ArgoCD project definitions)
```

---

## GitOps Bootstrapping: Installing ArgoCD

Because ArgoCD manages itself via GitOps, you need to perform a one-time manual install so it can pick up its Application manifest from this repo. After that, ArgoCD will manage itself and all other apps declaratively.

### 1. **Manually Install ArgoCD (One Time Only)**

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. **Wait for ArgoCD to Be Ready**

```
kubectl -n argocd get pods
```
Wait until all pods are `Running`.

### 3. **ArgoCD Syncs Its Application Manifest**

- ArgoCD will detect the `Application` manifest in `cluster/apps/argocd/app.yaml` and begin managing itself via Helm, as defined in this repo.

### 4. **(Optional but Recommended) Remove the Bootstrap Install**

Once ArgoCD is running and managing itself via the Application manifest, you can remove the bootstrap install to ensure only the Helm-managed version remains:

```
kubectl -n argocd delete -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
ArgoCD will immediately recreate the resources as managed by your Application manifest.

---

## Workflow

1. **Edit manifests in this repo** (add apps, update configs, etc).
2. **Push changes to GitHub**.
3. **ArgoCD automatically syncs changes to your cluster**.

---

## Next Steps
- Add and configure more applications (Keycloak, NGINX Ingress, etc) in `cluster/apps/`.
- Use ArgoCD UI to monitor and manage your cluster state.

---

## References
- [ArgoCD Docs](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [K3s Docs](https://rancher.com/docs/k3s/latest/en/) 