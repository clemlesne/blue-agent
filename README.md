# Azure Pipelines Agent

[Azure Pipelines Agent](https://github.com/clemlesne/azure-pipelines-agent) is self-hosted agent in Kubernetes, cheap to run, secure, auto-scaled and easy to deploy.

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/azure-pipelines-agent)](https://artifacthub.io/packages/search?repo=azure-pipelines-agent)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/azure-pipelines-agent-container)](https://artifacthub.io/packages/search?repo=azure-pipelines-agent-container)
[![Pipeline](https://github.com/clemlesne/azure-pipelines-agent/actions/workflows/pipeline.yaml/badge.svg)](https://github.com/clemlesne/azure-pipelines-agent/actions/workflows/pipeline.yaml)

Features:

- Agent register itself with the Azure DevOps server.
- Agent restart itself if it crashes.
- Agent update itself to the latest version.
- Auto-scale based on Pipeline usage (requires [KEDA](https://keda.sh)).
- Cheap to run (dynamic provisioning of agents, can scale to 0 and in few seconds 100+).
- Compatible with Debian, Ubuntu and Red Hat LTS releases.
- System updates are applied every days.
- SBOM (Software Bill of Materials) is packaged with each container image.
- Systems are based on [Microsoft official .NET images](https://mcr.microsoft.com/en-us/product/dotnet/aspnet/about).

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
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:bullseye-main` | Debian Bullseye (11) slim | `linux/amd64`, `linux/arm/v5`, `linux/arm/v7`, `linux/arm64/v8` | [See Debian LTS wiki.](https://wiki.debian.org/LTS) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:focal-main` | Ubuntu Focal (20.04) minimal | `linux/amd64`, `linux/arm/v7`, `linux/arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:jammy-main` | Ubuntu Jammy (22.04) minimal | `linux/amd64`, `linux/arm/v7`, `linux/arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:ubi8-main` | Red Hat UBI 8 | `linux/amd64`, `linux/arm64/v8` | [See Red Hat product life cycles.](https://access.redhat.com/product-life-cycles/?product=Red%20Hat%20Enterprise%20Linux) |

## Advanced topics

### Provided software

- [Azure Pipelines agent system requirements](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)
- [ASP.NET Core](https://github.com/dotnet/aspnetcore) runtime (required by the Azure Pipelines agent)
- [Azure CLI](https://github.com/Azure/azure-cli) (required by the Azure Pipelines agent)
- "make, tar, unzip, zip, zstd" (for developer ease-of-life)

### Helm values

| Parameter | Description | Default |
|-|-|-|
| `additionalEnv` | Additional environment variables for the agent container. | `[]` |
| `affinity` | Node affinity for pod assignment | `{}` |
| `autoscaling.cooldown` | Time in seconds the automation will wait until there is no more pipeline asking for an agent. Same time is then applied for system termination. | `60` |
| `autoscaling.enabled` | Enable the auto-scaling, requires [KEDA](https://keda.sh). | `true` |
| `autoscaling.maxReplicas` | Maximum number of pods, remaining jobs will be kept in queue. | `100` |
| `autoscaling.minReplicas` | Minimum number of pods. If autoscaling not enabled, the number of replicas to run. | `1` |
| `extraVolumeMounts` | Additional volume mounts for the agent container. | `[]` |
| `extraVolumes` | Additional volumes for the agent pod. | `[]` |
| `fullnameOverride` | Overrides release fullname | `""` |
| `image.pullPolicy` | Container image pull policy | `Always` if `image.tag` is `latest`, else `IfNotPresent` |
| `image.repository` | Container image repository | `ghcr.io/clemlesne/azure-pipelines-agent:bullseye` |
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
| `tagSuffix` | Container image tag | *App version* |
| `tolerations` | Toleration labels for pod assignment. | `[]` |

## Support

If you need help or found a bug, please feel free to open an issue on the [clemlesne/azure-pipelines-agent](https://github.com/clemlesne/azure-pipelines-agent) GitHub project.
