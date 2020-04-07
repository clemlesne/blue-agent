# Azure Pipelines Agent
[Azure Pipelines Agent](https://github.com/emberstack/docker-azure-pipelines-agent) is self-hosted agent that you can run in a container with Docker.

[![Build Status](https://dev.azure.com/emberstack/OpenSource/_apis/build/status/docker-azure-pipelines-agent?branchName=master)](https://dev.azure.com/emberstack/OpenSource/_build/latest?definitionId=17&branchName=master)
[![Release](https://img.shields.io/github/release/emberstack/docker-azure-pipelines-agent.svg?style=flat-square)](https://github.com/emberstack/docker-azure-pipelines-agent/releases/latest)
[![Docker Image](https://img.shields.io/docker/image-size/emberstack/azure-pipelines-agent/latest?style=flat-square)](https://hub.docker.com/r/emberstack/azure-pipelines-agent)
[![Docker Pulls](https://img.shields.io/docker/pulls/emberstack/azure-pipelines-agent.svg?style=flat-square)](https://hub.docker.com/r/emberstack/azure-pipelines-agent)
[![license](https://img.shields.io/github/license/emberstack/docker-azure-pipelines-agent.svg?style=flat-square)](LICENSE)
[![slack](https://img.shields.io/badge/join-emberstack%20on%20Slack-gray.svg?style=flat-square&longCache=true&logo=slack&colorB=green)](https://join.slack.com/t/emberstack/shared_invite/zt-8qyutopg-9ghwTq3OnHSm2tY9Sk5ULA)

> Supports `amd64`, `arm`

## Deployment

The Azure Pipeliens agent can be deployed either manually or using Helm (recommended).

### Support
If you need help or found a bug, please feel free to open an issue on the [emberstack/docker-azure-pipelines-agent](https://github.com/emberstack/docker-azure-pipelines-agent) GitHub project.  
  
You can also join our Slack workspace and talk to us:  
[![slack](https://img.shields.io/badge/join-emberstack%20on%20Slack-gray.svg?style=flat-square&longCache=true&logo=slack&colorB=green)](https://join.slack.com/t/emberstack/shared_invite/zt-8qyutopg-9ghwTq3OnHSm2tY9Sk5ULA)

#### Deployment using Helm

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

> Find us on [Helm Hub](https://hub.helm.sh/charts/emberstack)

