---
title: Troubleshooting
weight: 4
---

## Pods are evicted by Kubernetes with the message `Pod ephemeral local storage usage exceeds the total limit of containers`

This error is due to the fact that the default ephemeral storage limit is set to a lower value than the one used by the pipeline. You can fix it by setting the value to more than default value in `resources.limits.ephemeral-storage`.

This error notably happens when using BuildKit with an `emptyDir` and a large number of layers.

```yaml
# values.yaml (extract)
resources:
  limits:
    ephemeral-storage: 16Gi
```

## Pods are started but never selected by Azure DevOps when using multiple architectures

Prefer hardcoding the architecture in both the pipeline and the Helm values. As this, KEDA will be able to select the right pods matching the architecture. Otherwise, there is a possibility that the deployment selected by KEDA is not matching the requested architecture.

```yaml
# azure-pipelines.yaml (extract)
stages:
  - stage: test
    jobs:
      - job: test
        pool:
          demands:
            - arch_x64
```

```yaml
# values.yaml (extract)
extraNodeSelectors:
  kubernetes.io/arch: arm64

pipelines:
  capabilities:
    - arch_arm64
```

## Container fails to a `ContainerStatusUnknown` state

Error is often due to two things:

- Kubernetes is not able to pull the image: check the image name and the credentials, if you are using the public registry, mind the domain whitelist
- Pod has been ecivted by Kubernetes due to the excessive local storage usage: parameter `ephemeral-storage` in `resources` Helm values is set to `8Gi` by default, you can increase it to `16Gi` for example

## Namespaces must be set to a non-zero value

This error is due to the fact that BuildKit needs to create a new user namespace, and the default maximum number of namespaces is 0. Value is defined by `user.max_user_namespaces` ([documentation](https://man7.org/linux/man-pages/man7/namespaces.7.html)). You can fix it by setting the value to more than 1000. Issue notably happens on AWS Bottlerocket OS. [See related issue.](https://github.com/clemlesne/blue-agent/issues/19)

We can update dynamically the host system settings with a DaemonSet:

```yaml
# daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app.kubernetes.io/component: sysctl
    app.kubernetes.io/name: sysctl-max-user-ns-fix
    app.kubernetes.io/part-of: blue-agent
  name: sysctl-max-user-ns-fix
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: sysctl-max-user-ns-fix
  template:
    metadata:
      labels:
        app.kubernetes.io/name: sysctl-max-user-ns-fix
    spec:
      containers:
        - name: sysctl-max-user-ns-fix
          image: docker.io/library/busybox:1.36
          command:
            [
              "sh",
              "-euxc",
              "sysctl -w user.max_user_namespaces=63359 && sleep infinity",
            ]
          securityContext:
            privileged: true
```

## Change Buildkit working directory

If need Buildkit to write in another folder, then create the buildkitd.toml file and set the root variable. Example below (bash in the pipeline):

```bash
mkdir ~/.config/buildkit
echo 'root = "/app-root/.local/tmp/buildkit"' > ~/.config/buildkit/buildkitd.toml
```

## The agent has exceeded the 60-minute time limit

If the pipeline takes longer than 60 minutes, you need to change two things.

1. The technical pipeline timeout with `pipelines.timeout` Helm value to 7200 seconds (2 hours) for example.
2. Increase the functional pipeline timeout in Azure DevOps. Go to `Options > Build job > Build job timeout in minutes`.

{{< callout type="info" >}}
Set a technical pipeline timeout longer than the functional pipeline timeout to avoid the system to kill the pipeline abruptly.
{{< /callout >}}

![Configuration in the web interface.](build-job-timeout-in-minutes.png)

## Template container shows "no deploy tasks available" on first run

When autoscaling is enabled (KEDA), you may notice a first "template" container that runs for about 1 minute and then terminates with a message like "no deploy tasks available". **This is expected behavior**.

### Why template containers exist

Template containers serve as "parent" agents that:

- Register with Azure DevOps to establish the pool connection
- Allow KEDA to monitor the Azure DevOps pool for pending jobs
- Trigger autoscaling when jobs are queued
- Provide a reference point for KEDA's scaling decisions

### Expected behavior

The template container will:

1. Start with a name ending in `-template`
2. Register with your Azure DevOps pool
3. Run for approximately 1 minute
4. Show "no deploy tasks available" (because it's not meant to run jobs)
5. Terminate automatically

### How scaling works

1. Template container establishes pool connection
2. KEDA monitors the pool through this template agent
3. When jobs are queued, KEDA creates new job-running agents
4. These job-running agents process the actual pipeline jobs
5. After jobs complete, the job-running agents are cleaned up

This mechanism enables efficient autoscaling from 0 to 100+ agents based on your pipeline queue demand.
