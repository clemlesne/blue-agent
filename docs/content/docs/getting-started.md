---
next: /advanced-topics
prev: /docs
title: Getting started
weight: 1
---

## Usage

{{% steps %}}

### Prepare the Azure DevOps organization

Create [a new agent pool](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues) in Azure DevOps. Then, create [the personal access token](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/personal-access-token-agent-registration?view=azure-devops), with the scope `agent pools (read & manage)`, allowing access from the agent to Azure DevOps.

### Deploy

Software can either be deployed using Helm on a Kubernetes cluster or Bicep on Azure Container Apps.

{{% /steps %}}

## Deploy on Azure

{{< callout type="info" >}}
Azure deployment has a limitation regarding the demands and the OS:

- OS are limited to Linux, such as Debian, as Azure Containers Apps does not support Windows.
- The agent will not be able to run jobs requiring a system demand, such as `Agent.OS` or `Agent.OSArchitecture`. However, user-defined demands from the `pipelinesCapabilities` parameter are usable.

{{< /callout >}}

Deployment is using Bicep as a template language. Minimal configuration is required:

```bash
az deployment sub create \
  --location westeurope \
  --name blue-agent \
  --parameters \
    pipelinesOrganizationURL=https://dev.azure.com/your-organization \
    pipelinesPersonalAccessToken=your-pat \
    pipelinesPoolName=your-pool \
  --template-file src/bicep/main.bicep
```

The deployment will manage the resource provisioning, in a dedicated resource group. This includes (but is not limited to) Container Apps and Log Analytics.

Details about the Helm configuration [can be found in a dedicated section](../advanced-topics/bicep-deployment).

## Deploy on Kubernetes

{{% steps %}}

### Prepare the Helm values

Minimal configuration is required:

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
helm repo add clemlesne-blue-agent https://clemlesne.github.io/blue-agent
helm repo update
helm upgrade --install agent clemlesne-blue-agent/blue-agent
```

{{% /steps %}}

## Template Container Behavior

When deploying Blue Agent with KEDA auto-scaling enabled, a "template" container will run briefly during deployment. This is expected behavior that registers agent capabilities with Azure DevOps and enables KEDA scaling. The template container runs for 1 minute then stops (remaining as "offline" in the agent pool).

For detailed information about template container behavior, common errors, and troubleshooting, see the [troubleshooting documentation](/docs/troubleshooting/).

## OS support matrix

OS support is generally called "flavor" in this documentation. The following table shows the supported flavors and their characteristics.

| `Ref`                                            | OS                                                                           | `Size`                                                                                                             | `Arch`              | Support                                                                                                                                           |
| ------------------------------------------------ | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ghcr.io/clemlesne/blue-agent:azurelinux3-main`  | [Azure Linux 3](https://github.com/microsoft/azurelinux)                     | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/blue-agent/azurelinux3-main?label=)  | `amd64`, `arm64/v8` | [See Microsoft Azure documentation.](https://learn.microsoft.com/en-us/azure/aks/support-policies)                                                |
| `ghcr.io/clemlesne/blue-agent:bookworm-main`     | [Debian Bookworm (12)](https://www.debian.org/releases/bookworm) slim        | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/blue-agent/bookworm-main?label=)     | `amd64`, `arm64/v8` | [See Debian LTS wiki.](https://wiki.debian.org/LTS)                                                                                               |
| `ghcr.io/clemlesne/blue-agent:noble-main`        | [Ubuntu Noble (24.04)](https://www.releases.ubuntu.com/noble) minimal        | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/blue-agent/noble-main?label=)        | `amd64`             | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases)                                                                                          |
| `ghcr.io/clemlesne/blue-agent:jammy-main`        | [Ubuntu Jammy (22.04)](https://www.releases.ubuntu.com/jammy) minimal        | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/blue-agent/jammy-main?label=)        | `amd64`, `arm64/v8` | [See Ubuntu LTS wiki.](https://wiki.ubuntu.com/Releases)                                                                                          |
| `ghcr.io/clemlesne/blue-agent:ubi9-main`         | [Red Hat UBI 9](https://developers.redhat.com/articles/ubi-faq) minimal      | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/blue-agent/ubi9-main?label=)         | `amd64`, `arm64/v8` | [See Red Hat product life cycles.](https://access.redhat.com/product-life-cycles/?product=Red%20Hat%20Enterprise%20Linux)                         |
| `ghcr.io/clemlesne/blue-agent:ubi8-main`         | [Red Hat UBI 8](https://developers.redhat.com/articles/ubi-faq) minimal      | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/blue-agent/ubi8-main?label=)         | `amd64`, `arm64/v8` | [See Red Hat product life cycles.](https://access.redhat.com/product-life-cycles/?product=Red%20Hat%20Enterprise%20Linux)                         |
| `ghcr.io/clemlesne/blue-agent:win-ltsc2022-main` | [Windows Server 2022](https://learn.microsoft.com/en-us/windows-server) Core | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/blue-agent/win-ltsc2022-main?label=) | `amd64`             | [See base image servicing lifecycles.](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/base-image-lifecycle) |
| `ghcr.io/clemlesne/blue-agent:win-ltsc2019-main` | [Windows Server 2019](https://learn.microsoft.com/en-us/windows-server) Core | ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/clemlesne/blue-agent/win-ltsc2019-main?label=) | `amd64`             | [See base image servicing lifecycles.](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/base-image-lifecycle) |

## Docker Hub images

Container images are both published to GitHub Container Registry and Docker Hub. URLs showed in the doc are GitHub Container Registry URLs, for simplicity. To use Docker Hub, replace `ghcr.io/clemlesne/blue-agent` by `docker.io/clemlesne/blue-agent`. Docker Hub images are signed and secured the same way. [See the images at hub.docker.com.](https://hub.docker.com/r/clemlesne/blue-agent)
