# Variables
RELEASE_NAME ?= traefik
NAMESPACE ?= traefik

VALUES_FILE ?= chart/values.yaml
CHART_PATH ?= chart
CHART_FILE ?= $(CHART_PATH)/Chart.yaml

# Extract Traefik dependency version from Chart.yaml
TRAEFIK_CHART_VERSION := $(shell grep -A1 "name:[[:space:]]*traefik" $(CHART_FILE) | grep version | head -1 | awk '{print $$2}')

CONTAINER_RUNNER ?= docker
WORKDIR ?= $(shell pwd)
UID := $(shell id -u)
GID := $(shell id -g)

DOCKER_RUN_BASE := $(CONTAINER_RUNNER) run --rm -v $(WORKDIR):/workdir -w /workdir -u $(UID):$(GID)
DOCKER_RUN_HELM_DOCS := $(CONTAINER_RUNNER) run --rm -v $(WORKDIR)/chart:/helm-chart -w /helm-chart -u $(UID):$(GID)

.PHONY: help
help:
	@echo "Usage:"
	@echo "  make install        - Install $(RELEASE_NAME) in the cluster"
	@echo "  make upgrade        - Upgrade $(RELEASE_NAME) release"
	@echo "  make uninstall      - Uninstall $(RELEASE_NAME) release"
	@echo "  make install-crds   - Install Traefik CRDs for dependency version"
	@echo "  make uninstall-crds - Uninstall Traefik CRDs for dependency version"
	@echo "  make deps           - Update Helm chart dependencies"
	@echo "  make lint           - Lint the Helm chart"
	@echo "  make template       - Render Helm templates locally"
	@echo "  make yamllint       - Lint YAML files inside container"
	@echo "  make yamlfix        - Format YAML files inside container"
	@echo "  make helm-docs      - Generate Helm docs inside container"

## -------------------- Helm Chart Management --------------------

.PHONY: deps
deps:
	helm repo add traefik https://traefik.github.io/charts
	helm dependency update $(CHART_PATH)

.PHONY: install
install: deps
	helm install $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) --create-namespace \
		--skip-crds \
		-f $(VALUES_FILE)

.PHONY: upgrade
upgrade: deps
	helm upgrade $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		--skip-crds \
		-f $(VALUES_FILE)

.PHONY: uninstall
uninstall:
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)

.PHONY: install-crds
install-crds: deps
	@echo "Installing Traefik CRDs"
	helm show crds traefik/traefik --version $(TRAEFIK_CHART_VERSION) | kubectl apply -f -

.PHONY: uninstall-crds
uninstall-crds: deps
	@echo "Uninstalling Traefik CRDs"
	helm show crds traefik/traefik --version $(TRAEFIK_CHART_VERSION) | kubectl delete -f -

.PHONY: lint
lint: deps
	helm lint $(CHART_PATH)

.PHONY: template
template: deps
	helm template $(RELEASE_NAME) \
		$(CHART_PATH) \
		-f $(VALUES_FILE)

## -------------------- Container-Based Tools --------------------

.PHONY: yamllint
yamllint:
	@echo "Running yamllint container..."
	$(DOCKER_RUN_BASE) cytopia/yamllint:latest .

.PHONY: yamlfix
yamlfix:
	@echo "Running yamlfix container..."
	$(DOCKER_RUN_BASE) otherguy/yamlfix:latest .

.PHONY: helm-docs
helm-docs:
	@echo "Running helm-docs container..."
	$(DOCKER_RUN_HELM_DOCS) jnorwood/helm-docs:latest .
