kubectl create namespace keycloak-fips

# Create database credentials
kubectl create secret generic keycloak-db-secret  --from-literal=username=keycloak  --from-literal=password=keycloak123  --namespace=keycloak-fips

# Create Keycloak admin credentials
kubectl create secret generic keycloak-admin-secret  --from-literal=password=admin123 --namespace=keycloak-fips

openssl req -x509 -newkey rsa:2048 -keyout keycloak.key -out keycloak.crt -days 365 -nodes   -subj "/C=US/ST=State/L=City/O=Organization/CN=keycloak.local"

# Create PFX file
openssl pkcs12 -export -out keycloak.pfx -inkey keycloak.key -in keycloak.crt -password pass:changeit

# Create Kubernetes secret from PFX and certificate files
kubectl create secret generic keycloak-tls-secret  --from-file=keycloak.pfx=keycloak.pfx   --from-file=tls.crt=keycloak.crt   --from-file=tls.key=keycloak.key   --namespace=keycloak-fips

# Clean up local files
rm keycloak.key keycloak.crt keycloak.pfx


# Apply all configurations in order
kubectl apply -f fips-config.yaml
kubectl apply -f postgresql.yaml
kubectl apply -f keycloak.yaml

# Optional: Apply ingress if using Traefik
kubectl apply -f keycloak-ingress.yaml

# Wait for deployments to be ready
kubectl wait --for=condition=available --timeout=300s deployment/postgresql -n keycloak
kubectl wait --for=condition=available --timeout=600s deployment/keycloak -n keycloak