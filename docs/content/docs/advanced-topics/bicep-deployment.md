---
title: Deploy on Azure with Bicep
---

Bicep is a deployment language for Azure, allowing to easily deploy resources on the cloud.

#### Bicep parameters

| Parameter                      | Description                                                                                                                                | Default                           |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------- |
| `autoscalingMaxReplicas`       | Maximum number of simultaneous jobs the agent can run                                                                                      | `100`                             |
| `autoscalingMinReplicas`       | Minimum number of replicas the agent should have                                                                                           | `0`                               |
| `extraEnv`                     | Extra environment variables to pass to the agent                                                                                           | `[]`                              |
| `imageFlavor`                  | Flavor of the container image, represents the Linux distribution. Allowed values: `bookworm`, `bullseye`, `focal`, `jammy`, `ubi8`, `ubi9` | `bookworm`                        |
| `imageName`                    | Name of the container image                                                                                                                | `clemlesne/azure-pipelines-agent` |
| `imageRegistry`                | Registry of the container image. Allowed values: `docker.io`, `ghcr.io`                                                                    | `ghcr.io`                         |
| `imageVersion`                 | Version of the container image, it is recommended to use a specific version like "1.0.0" instead of "latest"                               | `main`                            |
| `instance`                     | Name of the instance, will be used to build the name of the resources                                                                      | Value from `deployment().name`    |
| `location`                     | Location of resources                                                                                                                      | `westeurope`                      |
| `pipelinesCapabilities`        | Capabilities of the agent                                                                                                                  | `['arch_x64']`                    |
| `pipelinesOrganizationURL`     | URL of the Azure DevOps organization                                                                                                       | _None_                            |
| `pipelinesPersonalAccessToken` | Personal access token allowing the agent to connect to the Azure DevOps organization. This parameter is secure.                            | _None_                            |
| `pipelinesPoolName`            | Name of the Azure Pipelines self-hosted pool the agent should be added to                                                                  | _None_                            |
| `pipelinesTimeout`             | Timeout in seconds for the agent to run a job before it is automatically terminated                                                        | `3600`                            |
| `resourcesCpu`                 | Number of CPU cores allocated to the agent                                                                                                 | `2`                               |
| `resourcesMemory`              | Amount of memory allocated to the agent                                                                                                    | `4Gi`                             |
