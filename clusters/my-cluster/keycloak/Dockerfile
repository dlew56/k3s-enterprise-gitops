# Use a multi-stage build to keep the final image lean
# Stage 1: Builder stage to download dependencies
FROM curlimages/curl:8.1.0 as builder

WORKDIR /tmp/providers

# Download Bouncy Castle FIPS JARs
# These versions are taken from your keycloak.yaml
RUN echo "Downloading Bouncy Castle FIPS JARs..." && \
    curl -L -o bc-fips-2.0.0.jar "https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/2.0.0/bc-fips-2.0.0.jar" && \
    curl -L -o bctls-fips-2.0.19.jar "https://repo1.maven.org/maven2/org/bouncycastle/bctls-fips/2.0.19/bctls-fips-2.0.19.jar" && \
    curl -L -o bcpkix-fips-2.0.7.jar "https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/2.0.7/bcpkix-fips-2.0.7.jar" && \
    curl -L -o bcutil-fips-2.0.3.jar "https://repo1.maven.org/maven2/org/bouncycastle/bcutil-fips/2.0.3/bcutil-fips-2.0.3.jar" && \
    echo "Verifying downloaded files:" && \
    ls -la .

# Stage 2: Final Keycloak image
FROM quay.io/keycloak/keycloak:23.0

# Switch to root user to change permissions
USER root

# Copy the downloaded FIPS provider JARs from the builder stage
COPY --from=builder /tmp/providers/*.jar /opt/keycloak/providers/

# Keycloak runs as user 1000. Set correct ownership for the copied files.
RUN chown 1000:1000 /opt/keycloak/providers/*.jar && \
    chmod 0644 /opt/keycloak/providers/*.jar

# Switch back to the keycloak user
USER 1000

# Optional: Verify the files are in the correct location
RUN ls -la /opt/keycloak/providers/
