# GitHub Copilot Instructions for Blue Agent

This file contains project-specific guidelines for GitHub Copilot to ensure code suggestions align with Blue Agent's mandatory conventions and best practices.

## Security and Compliance

### Container Image Signing

- All container images MUST be signed with Cosign
- Include `cosign sign` commands in CI/CD examples
- Use keyless signing with OIDC identity tokens when possible
- Example: `cosign sign --key="env://COSIGN_PRIVATE_KEY" --yes $IMAGE_TAG`
- Verify signatures with: `cosign verify --key cosign.pub $IMAGE_TAG`

### SLSA 4 Supply Chain Requirements

- All builds must generate SLSA provenance attestations
- Use `--provenance=true` flag in Docker build commands
- Include SBOM generation with `--sbom=true`
- Example: `docker build --provenance=true --sbom=true --tag $IMAGE .`
- Store provenance in container registry alongside images

### Secrets Management

- Never hardcode secrets in configuration files
- Use Azure Key Vault integration for Kubernetes secrets
- Prefer environment variables over files for secret injection
- Use SOPS for encrypting configuration files in repository
- Example: `sops -e config.yaml > config.enc.yaml`

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

## Container and Image Standards

### Base Image Selection

- Prefer official base images from Microsoft, Red Hat, or Canonical
- Support multiple OS flavors: azurelinux3, bookworm, jammy, noble, ubi8, ubi9
- Use minimal/slim variants when available
- Include Windows support with ltsc2019 and ltsc2022 variants

### Container Labels

- Include OCI-compliant labels in all container images
- Add ArtifactHub metadata labels for discoverability
- Use semantic versioning for image tags
- Example labels:

```dockerfile
LABEL org.opencontainers.image.title="Blue Agent"
LABEL org.opencontainers.image.description="Self-hosted Azure Pipelines agent"
LABEL org.opencontainers.image.vendor="clemlesne"
```

### Container Registry

- Support both GitHub Container Registry (ghcr.io) and Docker Hub
- Use multi-registry publishing for redundancy
- Implement proper image tagging strategy (latest, version, SHA)
- Include registry authentication in CI/CD examples

## Documentation Standards

### Hugo Documentation

- Use Hugo for all documentation generation
- Follow existing documentation structure and themes
- Include front matter with proper metadata
- Use shortcodes for consistent formatting
- Example front matter:

```yaml
---
title: "Page Title"
weight: 1
prev: /previous-page
next: /next-page
---
```

### Code Examples

- Include complete, runnable examples
- Test all code snippets in documentation
- Use proper syntax highlighting
- Include both minimal and advanced configuration examples

### Security Documentation

- Document all security features and requirements
- Include verification steps for signed artifacts
- Provide troubleshooting guides for common security issues
- Link to relevant security standards and compliance documents

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

## Specific Tool Versions

### Required Tools

- Cosign: v2.5.0
- Azure Pipelines Agent: v4.255.0
- Helm: v3.17.3
- Node.js: v22.15.0
- PowerShell: v7.4.7
- Python: v3.12.10

### Container Tools

- BuildKit: v0.21.1
- Docker Buildx: v0.23.0
- QEMU: Latest for multi-arch builds
- Hadolint: v2.12.0 for Dockerfile linting

## Performance and Scaling

### Resource Management

- Default CPU: 2 cores, Memory: 4Gi
- Ephemeral storage: 8Gi limit, 2Gi request
- Cache volume: 10Gi for Azure Pipelines directory
- Temp directory: 1Gi for standard TMPDIR

### Auto-scaling Configuration

- Min replicas: 0 (can scale to zero)
- Max replicas: 100 (configurable)
- Polling interval: 10 seconds
- Cooldown period: 60 seconds

## Common Patterns to Avoid

### Anti-patterns

- Do not use `kubectl apply` for application deployments
- Avoid hardcoded secrets in any configuration
- Never skip container signing for production images
- Do not use single-architecture builds
- Avoid using deprecated Azure DevOps APIs

### Legacy Patterns

- Do not reference old "Azure Pipelines Agent" naming
- Avoid classic Azure DevOps pipeline syntax
- Do not use ARM templates instead of Bicep
- Avoid non-OIDC authentication methods when possible

## Integration Examples

### Azure DevOps Integration

```yaml
# Azure Pipelines example
trigger:
  - main

pool:
  name: "blue-agent-pool"

steps:
  - task: Docker@2
    inputs:
      command: "build"
      dockerfile: "Dockerfile"
      arguments: "--platform=linux/amd64,linux/arm64"
  - script: |
      cosign sign --key="env://COSIGN_PRIVATE_KEY" --yes $(imageName)
    displayName: "Sign container image"
```

### Kubernetes Deployment

```yaml
# Helm values example
pipelines:
  organizationURL: "https://dev.azure.com/myorg"
  personalAccessToken: "$(azdo-pat)"
  poolName: "blue-agent-pool"

autoscaling:
  enabled: true
  minReplicas: 0
  maxReplicas: 50
  pollingInterval: 10

image:
  repository: "ghcr.io/clemlesne/blue-agent"
  flavor: "bookworm"
  version: "main"
```

This file serves as a comprehensive guide for GitHub Copilot to generate code suggestions that align with Blue Agent's architectural decisions, security requirements, and operational practices.
