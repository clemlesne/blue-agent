---
next: /advanced-topics
prev: /docs
title: Getting started
weight: 1
---

## Usage

{{% steps %}}

### Prepare the Azure DevOps organization

Create [a new agent pool](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues) in Azure DevOps. Then, create [the personal access token](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/personal-access-token-agent-registration?view=azure-devops) allowing access from the Agent to Azure DevOps.

### Prepare the Helm values

Minimal configuration:

```yaml
# values.yaml
pipelines:
  organizationURL: https://dev.azure.com/your-organization
  personalAccessToken: your-pat
  poolName: your-pool
```

Details about the Helm configuration [can be found in a dedicated section](../advanced-topics/helm-values).

### Install the chart

Use Helm to install the latest released chart:

```bash
helm repo add clemlesne-azure-pipelines-agent https://clemlesne.github.io/azure-pipelines-agent
helm repo update
helm upgrade --install agent clemlesne-azure-pipelines-agent/azure-pipelines-agent
```

{{% /steps %}}

## OS support matrix

OS support is generally called "flavor" in this documentation. The following table shows the supported flavors and their characteristics.

| `Ref`                                                       | OS                                                                           | `Size`                                                                                                                        | `Arch`              | Support                                                                                                                                           |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ghcr.io/clemlesne/azure-pipelines-agent:bookworm-main`     | [Debian Bookworm (12)](https://www.debian.org/releases/bookworm) slim        | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/azure-pipelines-agent/bookworm-main?label=)     | `amd64`, `arm64/v8` | [See Debian LTS wiki.](https://wiki.debian.org/LTS)                                                                                               |
| `ghcr.io/clemlesne/azure-pipelines-agent:bullseye-main`     | [Debian Bullseye (11)](https://www.debian.org/releases/bullseye) slim        | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/azure-pipelines-agent/bullseye-main?label=)     | `amd64`, `arm64/v8` | [See Debian LTS wiki.](https://wiki.debian.org/LTS)                                                                                               |
| `ghcr.io/clemlesne/azure-pipelines-agent:focal-main`        | [Ubuntu Focal (20.04)](https://www.releases.ubuntu.com/focal) minimal        | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/azure-pipelines-agent/focal-main?label=)        | `amd64`, `arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases)                                                                                          |
| `ghcr.io/clemlesne/azure-pipelines-agent:jammy-main`        | [Ubuntu Jammy (22.04)](https://www.releases.ubuntu.com/jammy) minimal        | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/azure-pipelines-agent/jammy-main?label=)        | `amd64`, `arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases)                                                                                          |
| `ghcr.io/clemlesne/azure-pipelines-agent:ubi8-main`         | [Red Hat UBI 8](https://developers.redhat.com/articles/ubi-faq) minimal      | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/azure-pipelines-agent/ubi8-main?label=)         | `amd64`, `arm64/v8` | [See Red Hat product life cycles.](https://access.redhat.com/product-life-cycles/?product=Red%20Hat%20Enterprise%20Linux)                         |
| `ghcr.io/clemlesne/azure-pipelines-agent:ubi9-main`         | [Red Hat UBI 9](https://developers.redhat.com/articles/ubi-faq) minimal      | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/azure-pipelines-agent/ubi9-main?label=)         | `amd64`, `arm64/v8` | [See Red Hat product life cycles.](https://access.redhat.com/product-life-cycles/?product=Red%20Hat%20Enterprise%20Linux)                         |
| `ghcr.io/clemlesne/azure-pipelines-agent:win-ltsc2019-main` | [Windows Server 2019](https://learn.microsoft.com/en-us/windows-server) Core | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/azure-pipelines-agent/win-ltsc2019-main?label=) | `amd64`             | [See base image servicing lifecycles.](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/base-image-lifecycle) |
| `ghcr.io/clemlesne/azure-pipelines-agent:win-ltsc2022-main` | [Windows Server 2022](https://learn.microsoft.com/en-us/windows-server) Core | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/azure-pipelines-agent/win-ltsc2022-main?label=) | `amd64`             | [See base image servicing lifecycles.](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/base-image-lifecycle) |

## Docker Hub images

Container images are both published to GitHub Container Registry and Docker Hub. URLs showed in the doc are GitHub Container Registry URLs, for simplicity. To use Docker Hub, replace `ghcr.io/clemlesne/azure-pipelines-agent` by `docker.io/clemlesne/azure-pipelines-agent`. Docker Hub images are signed and secured the same way. [See the images at hub.docker.com.](https://hub.docker.com/r/clemlesne/azure-pipelines-agent)
