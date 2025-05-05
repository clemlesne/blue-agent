# GitHub Copilot Instructions for Blue Agent

This file contains project-specific guidelines for GitHub Copilot to ensure code suggestions align with Blue Agent's mandatory conventions and best practices.

## Project Overview

Blue Agent is a self-hosted Azure Pipelines agent designed to run in Kubernetes environments. The project aims to provide a cost-effective, secure, auto-scaled, and easy-to-deploy alternative to Microsoft-hosted agents.

### Key Features and Motivations

- **Cost Efficiency**: Dynamic provisioning with KEDA auto-scaling (0 to 100+ agents in seconds)
- **Performance**: Customizable performance beyond Microsoft-hosted agent limitations
- **Security**: SBOM generation, Cosign signing, daily system updates, air-gapped capability
- **Flexibility**: Multi-OS support (Azure Linux, Debian, Ubuntu, RHEL, Windows Server)
- **Container Building**: Built-in BuildKit support for container builds
- **Self-Management**: Agent auto-registration and restart capabilities

### Core Architecture Components

- **Agent Runtime**: Multi-flavor container images with pre-installed tools (jq, PowerShell, Python 3, etc.)
- **Template Job System**: Special "template" containers (`AZP_TEMPLATE_JOB=1`) that register briefly to establish KEDA scaling capabilities
- **Multi-Deployment Target**: Both Kubernetes (via Helm) and Azure Container Apps (via Bicep)
- **Build Orchestration**: Make-based workflow with environment variable injection from `cicd/env-github-actions.sh`
- **Integration Testing**: Parallel test execution against live Azure DevOps pools using GNU parallel

### General Constraints

- **Container-First**: All deployments target container environments including Kubernetes and Azure Container Apps
- **Security-First**: All images must be signed, include SBOM, and follow SLSA 4 requirements
- **Multi-Architecture**: Support for both amd64 and arm64 architectures is mandatory
- **Cloud-Native**: Designed for cloud-native environments with KEDA integration
- **Documentation-Driven**: All features must be documented and examples provided

## Developer Workflows

### Build System (Make-based)

The project uses Make as the primary build orchestrator. Key commands:

```bash
# Local multi-flavor Docker builds
make build-docker flavor=bookworm version=latest

# Full deployment with Bicep (Azure Container Apps)
make deploy-bicep flavor=bookworm version=1.0.0

# Integration testing
make integration prefix=test flavor=bookworm version=1.0.0
```

Environment variables are centralized in `cicd/env-github-actions.sh` - always source this file when extending build scripts.

### Multi-Flavor Container Strategy

All Dockerfiles follow the pattern `src/docker/Dockerfile-{flavor}` where flavor corresponds to OS distributions:

- `alpine`, `azurelinux3`, `bookworm`, `jammy`, `noble` (Linux variants)
- `ubi8`, `ubi9` (Red Hat Enterprise Linux)
- `win-ltsc2022`, `win-ltsc2025` (Windows Server)

Build argument pattern is consistent across all flavors - check `cicd/docker-build-local.sh` for the canonical build argument list.

### Template Job Pattern

When developing KEDA integration features, understand the template job concept:

- Template containers run with `AZP_TEMPLATE_JOB=1`
- They register with Azure DevOps, establish capabilities, then exit after 60 seconds
- KEDA uses template agents as scaling references when no active agents exist
- See `src/docker/start.sh` lines 1-50 for the template job logic

### Integration Testing Architecture

Tests run in parallel using GNU parallel against live Azure DevOps organization:

- Organization: `https://dev.azure.com/blue-agent`
- Test pipeline definitions in `test/pipeline/*.yaml`
- Agent pool validation in `test/azure-devops/template-exists.sh`
- Cleanup verification in `test/azure-devops/queue-cleaned.sh`

## Security and Compliance

### SLSA 4 Supply Chain Requirements

- All builds must generate SLSA provenance attestations
- Use `--provenance=true` flag in Docker build commands
- Include SBOM generation with `--sbom=true`
- Example: `docker build --provenance=true --sbom=true --tag $IMAGE .`
- Store provenance in container registry alongside images

### Secrets Management

- Never hardcode secrets in configuration files
- Use SOPS for encrypted configuration: `sops -e config.yaml > config.enc.yaml`
- Azure Key Vault integration available in Helm chart (`secret.azureKeyVault.enabled`)
- Prefer environment variables over files for secret injection

### Multi-arch Support

- All container builds MUST support both amd64 and arm64 architectures
- Use `--platform=linux/amd64,linux/arm64` in Docker buildx commands
- Test both architectures in CI/CD pipeline
- Example: `docker buildx build --platform=linux/amd64,linux/arm64 --tag $IMAGE .`

## CI/CD and Azure Pipelines

### Azure Pipelines Target

- All CI snippets and examples MUST target Azure Pipelines
- Use YAML pipeline syntax, not classic editor
- Include KEDA auto-scaling configuration in pipeline examples
- Example pool configuration:

```yaml
pool:
  name: "my-agent-pool"
  demands:
    - agent.name -equals blue-agent
```

### KEDA Auto-scaling

- Include KEDA ScaledJob configuration in Kubernetes examples
- Use Azure Pipelines scaler for auto-scaling
- Set appropriate polling intervals (default: 10 seconds)
- Example KEDA trigger:

```yaml
triggers:
  - type: azure-pipelines
    metadata:
      organizationURL: "https://dev.azure.com/myorg"
      personalAccessToken: "pat_token"
      poolName: "my-pool"
```

### Pipeline Security

- Use service connections instead of hardcoded credentials
- Enable pipeline signing and verification
- Use Azure AD authentication where possible
- Implement least-privilege access for pipeline agents

## Deployment Targets and Configuration

### Helm for Kubernetes (Primary)

- Prefer Helm over kubectl for all Kubernetes deployments
- Chart location: `src/helm/blue-agent/`
- Default values in `src/helm/blue-agent/values.yaml`
- KEDA autoscaling enabled by default with Azure Pipelines scaler
- Example deployment:

```bash
helm install blue-agent clemlesne-blue-agent/blue-agent \
  --set pipelines.organizationURL="https://dev.azure.com/myorg" \
  --set pipelines.personalAccessToken="pat_token" \
  --set pipelines.poolName="my-pool"
```

### Bicep for Azure Container Apps

- Bicep templates in `src/bicep/`
- Subscription-level deployment with resource group creation
- Container Apps Job resource type for agent execution
- Parameter validation and secure parameter handling required

### Volume and Storage Patterns

Two volume types are standardized:

- **Cache volume**: Persistent storage for build caches (`pipelines.cache.size: 10Gi`)
- **Temp volume**: Ephemeral storage for job execution (`pipelines.tmpdir.size: 1Gi`)

Both support `managed-csi` type for Azure integration and can be disabled via `volumeEnabled: false`.

## Deployment and Tooling Preferences

### Helm Preference

- Prefer Helm over kubectl for all Kubernetes deployments
- Use `helm install` and `helm upgrade` commands in documentation
- Never suggest `kubectl apply` for application deployments
- Example: `helm install blue-agent clemlesne-blue-agent/blue-agent --values values.yaml`

### Bicep for Azure Resources

- Use Bicep templates for Azure resource deployments
- Prefer Bicep over ARM templates or Terraform
- Include proper parameter validation and descriptions
- Example: `az deployment sub create --template-file main.bicep --parameters @parameters.json`

### Configuration Management

- Use Helm values files for configuration management
- Support both values.yaml and values.json formats
- Implement proper parameter validation in Helm charts
- Use ConfigMaps for non-sensitive configuration

## Container and Tooling Standards

### Pre-installed Tool Versions

All container flavors include standardized tool versions (defined in `cicd/env-github-actions.sh`):

- Azure CLI, AWS CLI, GCloud CLI for multi-cloud support
- PowerShell Core (LTS 7.4.x), Python 3, Node.js 22.x
- Build tools: BuildKit, Git, JQ, YQ, Helm
- OS-specific: Tini for Linux, BuildTools for Windows

### Base Image Selection

- Prefer official base images from Microsoft, Red Hat, or Canonical
- Support multiple OS flavors: alpine, azurelinux3, bookworm, jammy, noble, ubi8, ubi9
- Use minimal/slim variants when available
- Include Windows support with ltsc2022 and ltsc2025 variants

### Container Labels and Metadata

- Include OCI-compliant labels in all container images
- Add ArtifactHub metadata for discoverability
- Use semantic versioning for image tags
- Registry support: Both GHCR (`ghcr.io`) and Docker Hub (`docker.io`)

## Documentation Standards

### Hugo Documentation Architecture

- Documentation site: `clemlesne.github.io/blue-agent`
- Hugo configuration: `docs/hugo.yaml`
- Theme: Hextra (Git submodule at `docs/themes/hextra/`)
- Structure: `/docs` (getting started), `/docs/advanced-topics`, `/docs/troubleshooting`
- All code examples must be tested and runnable

### Front Matter Pattern

```yaml
---
title: "Page Title"
weight: 1
prev: /previous-page
next: /next-page
---
```

## Development Guidelines

### Code Quality

- Use existing linting tools (Prettier, Hadolint, Helm lint)
- Follow existing code formatting standards
- Include proper error handling and logging
- Use semantic commit messages

### Testing

- Include unit tests for all new functionality
- Use integration tests for end-to-end scenarios
- Test multi-arch compatibility
- Validate security compliance in tests

### Versioning

- Use semantic versioning (MAJOR.MINOR.PATCH)
- Tag releases properly in Git
- Update version references in documentation
- Maintain backward compatibility when possible

## Common Patterns to Avoid

### Anti-patterns

- Do not use `kubectl apply` for application deployments (use Helm)
- Avoid hardcoded secrets in any configuration
- Never skip container signing for production images
- Do not use single-architecture builds
- Avoid using deprecated Azure DevOps APIs

### Legacy Patterns

- Do not reference old "Azure Pipelines Agent" naming (project renamed to Blue Agent)
- Avoid classic Azure DevOps pipeline syntax (use YAML)
- Do not use ARM templates instead of Bicep
- Avoid non-OIDC authentication methods when possible

This file serves as a comprehensive guide for GitHub Copilot to generate code suggestions that align with Blue Agent's architectural decisions, security requirements, and operational practices.
