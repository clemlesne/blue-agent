# Azure Pipelines Agent

<!-- Use absolute path for images in README.md, so that they are displayed on ArtifactHub.io, Lens, OpenLens, etc. -->
<img src="https://raw.githubusercontent.com/clemlesne/azure-pipelines-agent/main/logo-4096.png" width="100">

[Azure Pipelines Agent](https://github.com/clemlesne/azure-pipelines-agent) is self-hosted agent in Kubernetes, cheap to run, secure, auto-scaled and easy to deploy.

<!-- github.com badges -->
[![GitHub Release Date](https://img.shields.io/github/release-date/clemlesne/azure-pipelines-agent)](https://github.com/clemlesne/azure-pipelines-agent/releases)
[![GitHub Workflow Status (with branch)](https://img.shields.io/github/actions/workflow/status/clemlesne/azure-pipelines-agent/pipeline.yaml?branch=main)](https://github.com/clemlesne/azure-pipelines-agent/actions/workflows/pipeline.yaml)
[![GitHub all releases](https://img.shields.io/github/downloads/clemlesne/azure-pipelines-agent/total)](https://github.com/clemlesne/azure-pipelines-agent/pkgs/container/azure-pipelines-agent)

<!-- artifacthub.io badges -->
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/azure-pipelines-agent)](https://artifacthub.io/packages/search?repo=azure-pipelines-agent)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/azure-pipelines-agent-container)](https://artifacthub.io/packages/search?repo=azure-pipelines-agent-container)

Features:

- Agent register itself with the Azure DevOps server.
- Agent restart itself if it crashes.
- Auto-scale based on Pipeline usage (with [KEDA](https://keda.sh), not required).
- Can run air-gapped (no internet access).
- Cheap to run (scale to 0, dynamic provisioning of agents, can scale from 0 to 100+ in few seconds).
- Compatible with Debian, Ubuntu and Red Hat LTS releases.
- SBOM (Software Bill of Materials) is packaged with each container image.
- System updates are applied every days.
- Systems are based on [Microsoft official .NET images](https://mcr.microsoft.com/en-us/product/dotnet/aspnet/about) and [Red Hat Universal Base Image](https://catalog.redhat.com/software/containers/ubi8/ubi-minimal/5c359a62bed8bd75a2c3fba8).

## Usage

### Deployment in Kubernetes using Helm

Minimal configuration:

```yaml
pipelines:
  url: https://dev.azure.com/your-organization
  pat: your-pat
  pool: your-pool
```

Use Helm to install the latest released chart:

```bash
helm repo add clemlesne-azure-pipelines-agent https://clemlesne.github.io/azure-pipelines-agent
helm repo update
helm upgrade --install agent clemlesne-azure-pipelines-agent/azure-pipelines-agent
```

## Compatibility

| Ref | OS | Arch | Support |
|-|-|-|-|
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:bullseye-main` | Debian Bullseye (11) slim | `linux/amd64`, `linux/arm/v7`, `linux/arm64/v8` | [See Debian LTS wiki.](https://wiki.debian.org/LTS) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:focal-main` | Ubuntu Focal (20.04) minimal | `linux/amd64`, `linux/arm/v7`, `linux/arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:jammy-main` | Ubuntu Jammy (22.04) minimal | `linux/amd64`, `linux/arm/v7`, `linux/arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:ubi8-main` | Red Hat UBI 8 (8.7) minimal | `linux/amd64`, `linux/arm64/v8` | [See Red Hat product life cycles.](https://access.redhat.com/product-life-cycles/?product=Red%20Hat%20Enterprise%20Linux) |

## Advanced topics

### Provided software

- [Azure Pipelines agent](https://github.com/microsoft/azure-pipelines-agent), see env var `AGENT_VERSION` on the container images
- [Azure Pipelines system requirements](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)
- [ASP.NET Core](https://github.com/dotnet/aspnetcore) runtime (required by the Azure Pipelines agent)
- [Azure CLI](https://github.com/Azure/azure-cli) (required by the Azure Pipelines agent)
- "make, tar, unzip, gzip, zip, zstd" (for developer ease-of-life)

### Helm values

| Parameter | Description | Default |
|-|-|-|
| `additionalEnv` | Additional environment variables for the agent container. | `[]` |
| `affinity` | Node affinity for pod assignment | `{}` |
| `autoscaling.cooldown` | Time in seconds the automation will wait until there is no more pipeline asking for an agent. Same time is then applied for system termination. | `60` |
| `autoscaling.enabled` | Enable the auto-scaling, requires [KEDA](https://keda.sh). | `true` |
| `autoscaling.maxReplicas` | Maximum number of pods, remaining jobs will be kept in queue. | `100` |
| `autoscaling.minReplicas` | Minimum number of pods. If autoscaling not enabled, the number of replicas to run. If auto-scaling is enabled, it is recommended to set the value to `0`. | `1` |
| `extraVolumeMounts` | Additional volume mounts for the agent container. | `[]` |
| `extraVolumes` | Additional volumes for the agent pod. | `[]` |
| `fullnameOverride` | Overrides release fullname | `""` |
| `image.flavor` | Container image tag | `bullseye` |
| `image.pullPolicy` | Container image pull policy | `IfNotPresent` |
| `image.repository` | Container image repository | `ghcr.io/clemlesne/azure-pipelines-agent:bullseye` |
| `image.version` | Container image tag | *Version* |
| `initContainers` | InitContainers for the agent pod. | `[]` |
| `nameOverride` | Overrides release name | `""` |
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `pipelines.cacheSize` | Total cache the pipeline can take during execution, by default [the same amount as the Microsoft Hosted agents](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=yaml#hardware). | `10Gi` |
| `pipelines.cacheType` | Disk type to attach to the agents, see your cloud provider for mor details  ([Azure](https://learn.microsoft.com/en-us/azure/aks/concepts-storage#storage-classes), [AWS](https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html)). | `managed-csi` (Azure compatible) |
| `pipelines.pat` | Personal Access Token (PAT) used by the agent to connect. | *None* |
| `pipelines.pool` | Agent pool to which the Agent should register. | *None* |
| `pipelines.url` | The Azure base URL for your organization | *None* |
| `pipelines.workDir` | The work directory the agent should use | `_work` |
| `resources` | Resource limits | `{ "resources": { "limits": { "cpu": 2, "memory": "4Gi" }, "requests": { "cpu": 1, "memory": "2Gi" } }}` |
| `serviceAccount.create` | Create ServiceAccount | `true` |
| `serviceAccount.name` | ServiceAccount name | *Release name* |
| `tolerations` | Toleration labels for pod assignment. | `[]` |

## [Security](./SECURITY.md)

## [Authors](./AUTHORS.md)
