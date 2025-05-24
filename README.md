# Traefik Deployment

Helm chart for deploying [Traefik](https://traefik.io/) as a DaemonSet in a Kubernetes cluster.

## Purpose

This repository provides a modular, environment-agnostic Helm-based deployment for Traefik, using custom configuration optimized for advanced use cases such as deployment behind an external load balancer like **HAProxy**.  
This setup is designed to allow direct traffic on ports 80 and 443 via `hostNetwork`, enabling HAProxy (or similar external L4 load balancers) to route requests directly to the node IPs.  
It focuses on providing a secure and minimal setup that binds Traefik directly to node ports, without relying on Kubernetes `Service` resources.

It also integrates a `Makefile` to simplify common Helm operations, ensuring faster, more consistent, and automated deployments.


## Structure

- `chart/`: Helm chart directory containing Traefik resources:
    - `templates/`: Helm manifests for Traefik components.
    - `values.yaml`: Configuration for exposing Traefik via `hostPort`, enabling TLS redirect, proxy protocol, etc.
    - `Chart.yaml`: Helm chart metadata.
- `Makefile`: Automates Helm and YAML operations with consistent CLI commands.

## Installation (via Helm)

```bash
git clone https://github.com/YourUsername/traefik-k8s-deployment.git
cd traefik-k8s-deployment

# Update dependencies (if needed)
helm dependency update chart/

# Install Traefik
helm install traefik chart/ -f chart/values.yaml --namespace traefik --create-namespace
```

## Using the Makefile

The `Makefile` provides several convenient commands to manage Traefik deployments via Helm.

### 🔧 Variables

Override these via environment variables or CLI:

```makefile
RELEASE_NAME ?= traefik
NAMESPACE ?= traefik
VALUES_FILE ?= chart/values.yaml
CHART_PATH ?= chart
CONTAINER_RUNNER ?= docker
WORKDIR ?= $(shell pwd)
```

### 📦 Available Commands

| Command           | Description                                                        |
|------------------|--------------------------------------------------------------------|
| `make help`        | Show available commands                                            |
| `make deps`        | Update Helm chart dependencies                                    |
| `make install`     | Install Traefik with configured values                            |
| `make upgrade`     | Upgrade an existing Traefik release                               |
| `make uninstall`   | Uninstall the Traefik release                                     |
| `make lint`        | Lint the Helm chart                                               |
| `make template`    | Render Helm templates locally (dry-run)                           |
| `make yamllint`    | Lint YAML files using a containerized yamllint tool               |
| `make yamlfix`     | Format YAML files using a containerized yamlfix tool              |
| `make helm-docs`   | Generate Helm chart documentation inside a container              |

### 💡 Example usage

```bash
make install
make upgrade VALUES_FILE=chart/values.yaml
make lint
make yamllint
```

## Key Configuration Highlights

- **DaemonSet**: Runs one Traefik pod per node.
- **hostNetwork: true**: Enables direct access to node IP and ports.
- **Ports**: 
  - `web`: Exposes HTTP on port 80, redirects to HTTPS.
  - `websecure`: Exposes HTTPS on port 443.
- **Proxy Protocol**: Enabled with trusted IPs for HAProxy (e.g., `192.168.30.0/24`).
- **Tolerations**: Allows scheduling on control-plane nodes.

## Notes

- This chart assumes you have valid TLS certificates managed separately (e.g., via cert-manager).
- This setup is intended for environments where full control over node networking is required.
- The deployment is optimized for bare-metal or low-level cloud configurations.