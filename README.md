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
- Cheap to run (dynamic provisioning of agents, can scale from 0 to 100+ in few seconds).
- Compatible with Debian, Ubuntu and Red Hat LTS releases.
- SBOM (Software Bill of Materials) is packaged with each container image.
- System updates are applied every days.
- Systems are based on [Microsoft official .NET images](https://mcr.microsoft.com/en-us/product/dotnet/aspnet/about) and [Red Hat Universal Base Image](https://catalog.redhat.com/software/containers/ubi8/ubi-minimal/5c359a62bed8bd75a2c3fba8).

## Usage

Deployment steps:

1. [Prepare the token for allowing access from the Agent to Azure DevOps.](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops#permissions)
2. Deployment in Kubernetes using Helm

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

- [Azure Pipelines agent](https://github.com/microsoft/azure-pipelines-agent) (see env var `AGENT_VERSION` on the container images) + [requirements](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)
- [ASP.NET Core](https://github.com/dotnet/aspnetcore) runtime (required by the Azure Pipelines agent)
- [Azure CLI](https://github.com/Azure/azure-cli) (required by the Azure Pipelines agent) + requirements ([Python 3.8](https://www.python.org/downloads/release/python-380), [Python 3.9](https://www.python.org/downloads/release/python-390), [Python 3.10](https://www.python.org/downloads/release/python-3100), depending of the system, plus C/Rust build tools for libs non pre-built on the platforms)
- [Powershell](https://github.com/PowerShell/PowerShell), [bash](https://www.gnu.org/software/bash) and [zsh](https://www.zsh.org) (for inter-operability)
- [gzip](https://www.gnu.org/software/gzip), [make](https://www.gnu.org/software/make), [tar](https://www.gnu.org/software/tar), [unzip](https://infozip.sourceforge.net/UnZip.html), [wget](https://www.gnu.org/software/wget), [yq](https://github.com/mikefarah/yq), [zip](https://infozip.sourceforge.net/Zip.html), [zstd](https://github.com/facebook/zstd) (for developer ease-of-life)

### Capabilities

Capabilities are declarative variables you can add to the agents, to allow developers to select the right agent for their pipeline ([official documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/demands?view=azure-devops&tabs=yaml)).

> Note, you can add multiple Helm instances to the same agent pool. It will result in a single pool with multiple capabilities. Be warning, if a capability is not unique accross the pool, all the agents will scale. This will create "zoombies" agents, scaled for nothing, waiting their timeout.

Disctinct the agents by capabilities. For examples:

- A pool of X64 agents, and a pool of ARM64 agents
- A pool of agents with GPU, and a pool of agents without GPU
- A pool of agents with low performance (standard usage), and a pool of agents with high performance (IA training, intensive C/Rust/GraalVM compilation, ...), with distinct Kubernetes Node pool, scaling to 0 when not used ([AKS documentation](https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler))

#### Example: ARM64 agents

Take the assumption we want to host a specific instance pool to ARM servers.

```yaml
# values.yaml
pipelines:
  pool: onprem_kubernetes
  capabilities:
    - arch_arm64

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/arch
            operator: In
            values:
              - arm64
```

Deploy the Helm instance:

```bash
❯ helm upgrade --install agent-arm64 clemlesne-azure-pipelines-agent/azure-pipelines-agent -f values.yaml
```

Update the Azure Pipelines file in the repository to use the new pool:

```yaml
# azure-pipelines.yaml
pool:
  name: onprem_kubernetes
  demands:
    - Agent.OS -equals Linux
    - arch_arm64

stages:
  ...
```

### Build container images in the agent

Those methods can be used to build a container image:

| Software | Ease of use | Security impacts (sorted by) | Run location | Description |
|-|-|-|-|-|
| [Azure Container Registry task](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-tasks-overview#quick-task), [Google Cloud Build](https://cloud.google.com/build/docs/building/build-containers) | 🟩🟩🟥 | 🟩🟩🟩 | Managed environment | A managed service build the container image in a dedicated environment. |
| [Kaniko](https://github.com/GoogleContainerTools/kaniko#running-kaniko-in-a-kubernetes-cluster) | 🟩🟥🟥 | 🟩🟩🟩 | Self-hosted Kubernetes | A Pod is created for each build, taking care of building and pushing the container to the registry. No security drawbacks. |
| [img](https://github.com/genuinetools/img#running-with-kubernetes), [BuildKit](https://github.com/moby/buildkit) | 🟩🟩🟩 | 🟩🟥🟥 | Local CLI | Daemon-less CLI to build the images. Required [Seccomp](https://en.wikipedia.org/wiki/Seccomp) and [AppArmor](https://apparmor.net) to be disabled. |
| Docker in docker | 🟩🟩🟩 | 🟥🟥🟥 | Local CLI | Before Kubernetes 1.20, it was possible to build container images in the agent, using the Docker socket. This is not possible anymore, as Kubernetes [deprecated the Docker socket](https://kubernetes.io/blog/2020/12/02/dont-panic-kubernetes-and-docker) in favor of the [Container Runtime Interface](https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes). |

### Helm values

| Parameter | Description | Default |
|-|-|-|
| `additionalEnv` | Additional environment variables for the agent container. | `null` |
| `affinity` | Node affinity for pod assignment | `null` |
| `annotations` | Add custom annotations to the Pod. | `null` |
| `autoscaling.cooldown` | Time in seconds the automation will wait until there is no more pipeline asking for an agent. Same time is then applied for system termination. | `60` |
| `autoscaling.enabled` | Enable the auto-scaling, requires [KEDA](https://keda.sh). | `true` |
| `autoscaling.maxReplicas` | Maximum number of pods, remaining jobs will be kept in queue. | `100` |
| `autoscaling.minReplicas` | Minimum number of pods. If autoscaling not enabled, the number of replicas to run. If `pipelines.capabilities` is defined, cannot be set to `0`. | `1` |
| `extraVolumeMounts` | Additional volume mounts for the agent container. | `null` |
| `extraVolumes` | Additional volumes for the agent pod. | `null` |
| `fullnameOverride` | Overrides release fullname | `""` |
| `image.flavor` | Container image tag | `bullseye` |
| `image.pullPolicy` | Container image pull policy | `IfNotPresent` |
| `image.repository` | Container image repository | `ghcr.io/clemlesne/azure-pipelines-agent:bullseye` |
| `image.version` | Container image tag | *Version* |
| `imagePullSecrets` | Use secrets to pull the container image. | `null` |
| `initContainers` | InitContainers for the agent pod. | `null` |
| `nameOverride` | Overrides release name | `""` |
| `nodeSelector` | Node labels for pod assignment | `null` |
| `pipelines.cacheSize` | Total cache the pipeline can take during execution, by default [the same amount as the Microsoft Hosted agents](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=yaml#hardware). | `10Gi` |
| `pipelines.cacheType` | Disk type to attach to the agents, see your cloud provider for mor details  ([Azure](https://learn.microsoft.com/en-us/azure/aks/concepts-storage#storage-classes), [AWS](https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html)). | `managed-csi` (Azure compatible) |
| `pipelines.capabilities` | Add [demands/capabilities](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/demands?view=azure-devops&tabs=yaml) to the agent | `[]` |
| `pipelines.pat` | Personal Access Token (PAT) used by the agent to connect. | *None* |
| `pipelines.pool` | Agent pool to which the Agent should register. | *None* |
| `pipelines.timeout` | Time in seconds after a agent will be stopped, the same amount of time is applied as a timeout for the system to shut down. | `3600` (1 hour) |
| `pipelines.url` | The Azure base URL for your organization | *None* |
| `resources` | Resource limits | `{ "resources": { "limits": { "cpu": 2, "memory": "4Gi" }, "requests": { "cpu": 1, "memory": "2Gi" } }}` |
| `serviceAccount.create` | Create ServiceAccount | `true` |
| `serviceAccount.name` | ServiceAccount name | *Release name* |
| `tolerations` | Toleration labels for pod assignment. | `null` |

## [Security](./SECURITY.md)

## [Authors](./AUTHORS.md)
