# Set paths to your local Git-tracked files
$basePath = "C:\alx\k3s\cluster\base"
$appsPath = "C:\alx\k3s\cluster\apps\argocd"

Write-Host "🔄 Recreating namespace..."
kubectl delete ns argocd --ignore-not-found
kubectl create namespace argocd

Write-Host "📥 Reapplying ArgoCD install.yaml..."
kubectl apply -n argocd -f "$basePath\argocd-install.yaml"

Write-Host "⏳ Waiting for ArgoCD pods to come up..."
kubectl -n argocd wait --for=condition=Available --timeout=90s deployment/argocd-server
kubectl -n argocd get pods

Write-Host "🔁 Reapplying ArgoCD self-managing app.yaml..."
kubectl apply -f "$appsPath\app.yaml"

# Optional: If you're managing this service manually and it's not in Helm anymore
$svcPath = "$basePath\argocd-repo-server-service.yaml"
if (Test-Path $svcPath) {
    Write-Host "🌐 Reapplying manually managed argocd-repo-server service..."
    kubectl apply -f $svcPath
}

Write-Host "`n✅ Done. Check:"
Write-Host "  kubectl -n argocd get pods"
Write-Host "  kubectl -n argocd get application"
Write-Host "  kubectl -n argocd get endpoints argocd-repo-server"
