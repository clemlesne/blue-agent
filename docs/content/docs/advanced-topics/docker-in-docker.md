---
title: Build container images
---

These methods can be used to build a container image, at the time of writing:

| Software                                                                                                                                                                                                                      | Ease   | Security | Perf   | Run location           | Description                                                                                                                                                                                                                                                                                                                                                                                  |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | -------- | ------ | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Azure Container Registry task](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-tasks-overview#quick-task), [Google Cloud Build](https://cloud.google.com/build/docs/building/build-containers) | 🟩🟩🟥 | 🟩🟩🟩   | 🟩🟩🟩 | Managed environment    | A managed service build the container image in a dedicated environment.                                                                                                                                                                                                                                                                                                                      |
| [Kaniko](https://github.com/GoogleContainerTools/kaniko#running-kaniko-in-a-kubernetes-cluster)                                                                                                                               | 🟩🟥🟥 | 🟩🟩🟩   | 🟩🟩🟥 | Self-hosted Kubernetes | A Pod is created for each build, taking care of building and pushing the container to the registry. No security drawbacks.                                                                                                                                                                                                                                                                   |
| [img](https://github.com/genuinetools/img#running-with-kubernetes), [BuildKit](https://github.com/moby/buildkit)                                                                                                              | 🟩🟩🟩 | 🟩🟩🟥   | 🟩🟥🟥 | Local CLI              | CLI to build the images. Can build different architectures on a single machine. Requires [Seccomp](https://en.wikipedia.org/wiki/Seccomp) disabled and [AppArmor](https://apparmor.net) disabled.                                                                                                                                                                                            |
| Docker in docker                                                                                                                                                                                                              | 🟩🟩🟩 | 🟥🟥🟥   | 🟩🟩🟩 | Local CLI              | Before Kubernetes 1.20, it was possible to build container images in the agent, using the Docker socket. This is not possible anymore, as Kubernetes [deprecated the Docker socket](https://kubernetes.io/blog/2020/12/02/dont-panic-kubernetes-and-docker) in favor of the [Container Runtime Interface](https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes). |

We choose BuildKit for this project. [Its license](https://raw.githubusercontent.com/moby/buildkit/v0.11.5/LICENSE) allows commercial use, and the project and mainly maintained, as the time of writing, by Docker, Netlix and Microsoft.

Linux systems are supported, but not Windows:

| `Ref`                                                       | Container build inside of the agent with BuildKit |
| ----------------------------------------------------------- | ------------------------------------------------- |
| `ghcr.io/clemlesne/azure-pipelines-agent:bookworm-main`     | ✅                                                |
| `ghcr.io/clemlesne/azure-pipelines-agent:bullseye-main`     | ✅                                                |
| `ghcr.io/clemlesne/azure-pipelines-agent:focal-main`        | ✅                                                |
| `ghcr.io/clemlesne/azure-pipelines-agent:jammy-main`        | ✅                                                |
| `ghcr.io/clemlesne/azure-pipelines-agent:ubi8-main`         | ✅                                                |
| `ghcr.io/clemlesne/azure-pipelines-agent:ubi9-main`         | ✅                                                |
| `ghcr.io/clemlesne/azure-pipelines-agent:win-ltsc2019-main` | ❌                                                |
| `ghcr.io/clemlesne/azure-pipelines-agent:win-ltsc2022-main` | ❌                                                |

#### How to use the bundled BuildKit

There are two components, the backend, `buildkitd`, and the CLI, `buildctl`.

Requirements:

- Setup special security requirements, you can find them [in the example file `container-build.yaml`](example/helm/container-build.yaml).
- In the pipeline, run `buildkitd` before using `buildctl`.

```yaml
# azure-pipelines.yaml
variables:
  - name: container_name
    value: my-app
  - name: container_registry_domain
    value: my-app-registry.azurecr.io

steps:
  - bash: |
      # Start buildkitd
      rootlesskit buildkitd --oci-worker-no-process-sandbox --addr $BUILDKIT_HOST &
      # Wait for buildkitd to start
      while ! buildctl debug workers; do sleep 1; done
    displayName: Run BuildKit

  - bash: |
      buildctl build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$(container_registry_domain)/$(container_name):latest,push=true
    displayName: Build and push the image
```

Out of the box, argument `--opt platform=linux/amd64,linux/arm64` can be added to build an image compatible with multiple architectures ([more can be specified](https://github.com/moby/buildkit/blob/v0.11.5/docs/multi-platform.md)). Multiple cache strategies [are available](https://github.com/moby/buildkit/tree/v0.11.5#cache) (including container registry, Azure Storage Blob, AWS S3).

#### BuildKit and the performance

BuildKit works by virtualization in the user space. You can't expect build times as short as native (on your laptop for example). [QEMU](https://www.qemu.org) is used as a backend. This has the advantage of being able to create images for different architectures than your processor. Virtualization-wise, not all CPU models are equivalent, you can [refer to the official project documentation](https://www.qemu.org/docs/master/system/qemu-cpu-models.html) to select the most appropriated CPU model for your Kubernetes Node Pool.
