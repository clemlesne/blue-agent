# Introduction
[Azure Pipelines Agent](https://github.com/emberstack/docker-azure-pipelines-agent) is self-hosted agent that you can run in a container with Docker.

> Supports `amd64`, `arm`

## Installing the Chart

You can install the chart with the release name `azure-pipelines-agent` as below:
```shellsession
$ helm repo add emberstack https://emberstack.github.io/helm-charts
$ helm repo update
$ helm upgrade --install azure-pipelines-agent emberstack/azure-pipelines-agent
```
> Note - If you do not specify a name, helm will select a name for you.

### Values
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


## Upgrading the Chart
You can upgrade using the following command:
```console
$ helm upgrade <HELM_RELEASE_NAME> emberstack/azure-pipelines-agent
```

## Uninstalling the Chart
To uninstall/delete the `my-release` deployment:
```console
$ helm delete my-release
```