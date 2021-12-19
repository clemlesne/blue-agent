# Azure Pipelines Agent
[Azure Pipelines Agent](https://github.com/emberstack/docker-azure-pipelines-agent) is self-hosted agent that you can run in a container with Docker.

[![Pipeline](https://github.com/emberstack/docker-azure-pipelines-agent/actions/workflows/pipeline.yaml/badge.svg)](https://github.com/emberstack/docker-azure-pipelines-agent/actions/workflows/pipeline.yaml)
[![Release](https://img.shields.io/github/release/emberstack/docker-azure-pipelines-agent.svg?style=flat-square)](https://github.com/emberstack/docker-azure-pipelines-agent/releases/latest)
[![Docker Image](https://img.shields.io/docker/image-size/emberstack/azure-pipelines-agent/latest?style=flat-square)](https://hub.docker.com/r/emberstack/azure-pipelines-agent)
[![Docker Pulls](https://img.shields.io/docker/pulls/emberstack/azure-pipelines-agent.svg?style=flat-square)](https://hub.docker.com/r/emberstack/azure-pipelines-agent)
[![license](https://img.shields.io/github/license/emberstack/docker-azure-pipelines-agent.svg?style=flat-square)](LICENSE)

> Supports `amd64`, `arm` and `arm64`

## Agent Version

This image will automatically pull and install the latest Azure DevOps version at startup.

### Support
If you need help or found a bug, please feel free to open an issue on the [emberstack/docker-azure-pipelines-agent](https://github.com/emberstack/docker-azure-pipelines-agent) GitHub project.  

## Deployment

The Azure Pipeliens agent can be deployed in Docker using either `docker run` or `docker compose` or in Kubernetes using Helm (recommended).

#### Deployment in `docker`

```
docker run -d -e AZP_AGENT_NAME="<agent name>" -e AZP_URL="https://dev.azure.com/<your org.>" -e AZP_POOL="<agent pool>" -e AZP_TOKEN="<PAT>" emberstack/azure-pipelines-agent
```


#### Deployment in `Kubernetes` using `Helm`

Use Helm to install the latest released chart:
```shellsession
$ helm repo add emberstack https://emberstack.github.io/helm-charts
$ helm repo update
$ helm upgrade --install azure-pipelines-agent emberstack/azure-pipelines-agent
```

You can customize the values of the helm deployment by using the following Values:

| Parameter                            | Description                                                 | Default                                                 |
| ------------------------------------ | ----------------------------------------------------------- | ------------------------------------------------------- |
| `nameOverride`                       | Overrides release name                                      | `""`                                                    |
| `fullnameOverride`                   | Overrides release fullname                                  | `""`                                                    |
| `image.repository`                   | Container image repository                                  | `emberstack/azure-pipelines-agent`                      |
| `image.tag`                          | Container image tag                                         | `""` (same version as the chart)                        |
| `image.pullPolicy`                   | Container image pull policy                                 | `Always` if `image.tag` is `latest`, else `IfNotPresent`|
| `pipelines.url`                      | The Azure base URL for your organization                    | `""`                                                    |
| `pipelines.pat`                      | Personal Access Token (PAT) used by the agent to connect.   | `""`                                                    |
| `pipelines.pool`                     | Agent pool to which the Agent should register.              | `""`                                                    |
| `pipelines.agent.mountDocker`        | Enable to mount the host `docker.sock`                      | `false`                                                 |
| `pipelines.agent.workDir`            | The work directory the agent should use                     | `_work`                                                 |
| `serviceAccount.create`              | Create ServiceAccount                                       | `true`                                                  |
| `serviceAccount.name`                | ServiceAccount name                                         | _release name_                                          |
| `serviceAccount.clusterAdmin`        | Sets the service account as a cluster admin                 | _release name_                                          |
| `resources`                          | Resource limits                                             | `{}`                                                    |
| `nodeSelector`                       | Node labels for pod assignment                              | `{}`                                                    |
| `tolerations`                        | Toleration labels for pod assignment                        | `[]`                                                    |
| `affinity`                           | Node affinity for pod assignment                            | `{}`                                                    |

> Find us on [Artifact Hub](https://artifacthub.io/packages/helm/emberstack/azure-pipelines-agent)
