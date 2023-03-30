# Azure Pipelines Agent

[Azure Pipelines Agent](https://github.com/clemlesne/azure-pipelines-agent) is self-hosted agent that you can run in a container with Kubernetes.

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/azure-pipelines-agent)](https://artifacthub.io/packages/search?repo=azure-pipelines-agent)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/azure-pipelines-agent-container)](https://artifacthub.io/packages/search?repo=azure-pipelines-agent-container)
[![Pipeline](https://github.com/clemlesne/azure-pipelines-agent/actions/workflows/pipeline.yaml/badge.svg)](https://github.com/clemlesne/azure-pipelines-agent/actions/workflows/pipeline.yaml)

## Usage

- This image will automatically pull and install the latest Azure DevOps version at startup.

### Deployment in Kubernetes using Helm

Use Helm to install the latest released chart:

```bash
helm repo add clemlesne-azure-pipelines-agent https://clemlesne.github.io/azure-pipelines-agent
helm repo update
helm upgrade --install agent clemlesne-azure-pipelines-agent/azure-pipelines-agent
```

> Find us on [Artifact Hub](https://artifacthub.io/packages/helm/clemlesne/azure-pipelines-agent)

You can customize the values of the helm deployment by using the following Values:

| Parameter | Description | Default |
|-|-|-|
| `additionalEnv` | Additional environment variables for the agent container. | `[]` |
| `affinity` | Node affinity for pod assignment | `{}` |
| `extraVolumeMounts` | Additional volume mounts for the agent container. | `[]` |
| `extraVolumes` | Additional volumes for the agent pod. | `[]` |
| `fullnameOverride` | Overrides release fullname | `""` |
| `image.pullPolicy` | Container image pull policy | `Always` if `image.tag` is `latest`, else `IfNotPresent` |
| `image.repository` | Container image repository | `clemlesne/azure-pipelines-agent` |
| `image.tag` | Container image tag | `""` (same version as the chart) |
| `initContainers` | InitContainers for the agent pod. | `[]` |
| `nameOverride` | Overrides release name | `""` |
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `pipelines.agent.mountDocker` | Enable to mount the host `docker.sock` | `false` |
| `pipelines.agent.workDir` | The work directory the agent should use | `_work` |
| `pipelines.pat.secretRef` | The reference to the secret storing the Personal Access Token (PAT) used by the agent to connect. | `""` |
| `pipelines.pat.value` | Personal Access Token (PAT) used by the agent to connect. | `""` |
| `pipelines.pool` | Agent pool to which the Agent should register. | `""` |
| `pipelines.url` | The Azure base URL for your organization | `""` |
| `resources` | Resource limits | `{}` |
| `serviceAccount.clusterAdmin` | Sets the service account as a cluster admin | _release name_ |
| `serviceAccount.create` | Create ServiceAccount | `true` |
| `serviceAccount.name` | ServiceAccount name | _release name_ |
| `tolerations` | Toleration labels for pod assignment | `[]` |

### Compatibility

| Ref | OS | Arch | Support |
|-|-|-|-|
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:bullseye-master` | Debian Bullseye (11) slim | `linux/amd64`, `linux/arm/v5`, `linux/arm/v7`, `linux/arm64/v8` | [See Debian LTS wiki.](https://wiki.debian.org/LTS) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:buster-master` | Debian Buster (10) slim | `linux/amd64`, `linux/arm/v7`, `linux/arm64/v8` | [See Debian LTS wiki.](https://wiki.debian.org/LTS) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:bionic-master` | Ubuntu Bionic (18.04) minimal | `linux/amd64`, `linux/arm/v7`, `linux/arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:focal-master` | Ubuntu Focal (20.04) minimal | `linux/amd64`, `linux/arm/v7`, `linux/arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases) |
| `docker pull ghcr.io/clemlesne/azure-pipelines-agent:jammy-master` | Ubuntu Jammy (22.04) minimal | `linux/amd64`, `linux/arm/v7`, `linux/arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases) |

## Support

If you need help or found a bug, please feel free to open an issue on the [clemlesne/azure-pipelines-agent](https://github.com/clemlesne/azure-pipelines-agent) GitHub project.
