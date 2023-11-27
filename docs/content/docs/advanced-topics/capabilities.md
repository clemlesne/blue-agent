---
title: Capabilities
---

Capabilities are declarative variables you can add to the agents, to allow developers to select the right agent for their pipeline ([official documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/demands?view=azure-devops&tabs=yaml)).

{{< callout type="info" >}}
Multiple Helm instances can be deployed using the same agent pool name (see `pipelines.poolName`). It will result in a single pool with multiple capabilities. Be warning, if a capability is not unique accross the pool, all the agents will scale. This will create "zoombies" agents, scaled for nothing, waiting their timeout.
{{< /callout >}}

Disctinct the agents by capabilities. For examples:

- A pool of X64 agents, and a pool of ARM64 agents
- A pool of agents with GPU, and a pool of agents without GPU
- A pool of agents with low performance (standard usage), and a pool of agents with high performance (IA training, intensive C/Rust/GraalVM compilation, ...), with distinct Kubernetes Node pool, scaling to 0 when not used ([AKS documentation](https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler))

#### Example: ARM64 agents

Take the assumption we want to host a specific instance pool to ARM servers.

```yaml
# values.yaml
pipelines:
  poolName: private_kube
  capabilities:
    - arch_arm64

extraNodeSelectors:
  kubernetes.io/arch: arm64
```

Deploy the Helm instance:

```bash
❯ helm upgrade --install agent-arm64 clemlesne-azure-pipelines-agent/azure-pipelines-agent -f values.yaml
```

Update the Azure Pipelines file in the repository to use the new pool:

```yaml
# azure-pipelines.yaml
pool:
  name: private_kube
  demands:
    - arch_arm64

stages: ...
```

#### Example: Use different agents on specific jobs

In that example:

- We are using a default agent on ARM64
- Semgrep, our SAST tool, is not compatible with ARM64, let's use X64 pool
- Our devs are working on a Java project, built with GraalVM, and the container is built locally with BuildKit: we need a system lot of RAM and multipe CPUs for building the application

Our problematic:

- Is it possible to reconcile the efficiency of these different architectures, without restricting ourselves?
- Do we necessarily have to install high performance agents when the use of these large constructions is only a small part of the total execution time (tests, deployments, monitoring, rollback, external services, ...)?

We decide to dpeloy these agents:

| Details                     | Efficiency (cost, perf, energy) | Capabilities                  |
| --------------------------- | ------------------------------- | ----------------------------- |
| Standard performance, ARM64 | ≅ x1                            | `arch_arm64`, `perf_standard` |
| Standard performance, X64   | ≅ x1.5                          | `arch_x64`, `perf_standard`   |
| High performance, ARM64     | ≅ x10                           | `arch_x64`, `perf_high`       |
| High performance, X64       | ≅ x15                           | `arch_arm64`, `perf_high`     |

The developer can now use:

```yaml
# azure-pipelines.yaml
pool:
  name: private_kube
  demands:
    - arch_arm64
    - perf_standard

stages:
  - stage: build
    jobs:
      - job: sast
        # Use X64 Linux agent because Semgrep is not available on ARM64
        # See: https://github.com/returntocorp/semgrep/issues/2252
        pool:
          name: private_kube
          demands:
            - arch_x64
            - perf_standard
      - job: unit_tests
      - job: container
        # Use high performance agent as Java GraalVM compilation is complex
        pool:
          name: private_kube
          demands:
            - arch_x64
            - perf_high
  - stage: deploy
    jobs:
      - job: upgrade
      - job: dast
      - job: integration_tests
```
