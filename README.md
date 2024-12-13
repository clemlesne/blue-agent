> [!IMPORTANT]
> Project name is now Blue Agent! Was previously known as Azure Pipelines Agent.

# Blue Agent

<!-- Use absolute path for images in README.md, so that they are displayed on ArtifactHub.io, Lens, OpenLens, etc. -->
<img src="https://raw.githubusercontent.com/clemlesne/blue-agent/main/docs/static/favicon.svg" width="100">

[Blue Agent](https://github.com/clemlesne/blue-agent) is self-hosted agent in Kubernetes, cheap to run, secure, auto-scaled and easy to deploy.

<!-- github.com badges -->

[![Last release date](https://img.shields.io/github/release-date/clemlesne/blue-agent)](https://github.com/clemlesne/blue-agent/releases)
[![Project license](https://img.shields.io/github/license/clemlesne/blue-agent)](https://github.com/clemlesne/blue-agent/blob/main/LICENSE)

<!-- artifacthub.io badges -->

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/blue-agent)](https://artifacthub.io/packages/search?repo=blue-agent)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/blue-agent-container)](https://artifacthub.io/packages/search?repo=blue-agent-container)

## Celebrating the community

We broke through 2,000,000 container pulls in August! 🎉

## Features

- 🔄 Agent register and restart itself.
- 🏗️ Allow to build containers inside the agent using [BuildKit](https://github.com/moby/buildkit).
- 🔒 Build authenticity can be cryptographically verified with [Cosign](https://github.com/sigstore/cosign) and GPG.
- 📵 Can run air-gapped (no internet access).
- 💰 Cheap to run (dynamic provisioning of agents, can scale from 0 to 100+ in few seconds with [KEDA](https://keda.sh)).
- 💪 Performances can be customized depending of the engineering needs, which goes far beyond the Microsoft-hosted agent.
- 🖥️ Pre-built with [Windows Server](https://www.microsoft.com/en-us/windows-server), [Debian](https://debian.org), [Ubuntu](https://ubuntu.com), [Red Hat Enterprise Linux](https://access.redhat.com/products/red-hat-enterprise-linux).
- 📦 [SBOM (Software Bill of Materials)](https://en.wikipedia.org/wiki/Software_supply_chain) is packaged with each container image.
- 🔄 System updates are applied every day.

## How to deploy

[Deployment is available](https://clemlesne.github.io/blue-agent/docs/getting-started) using Helm on a Kubernetes cluster or Bicep on Azure Container Apps.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fclemlesne%2Fblue-agent%2Fmain%2Fsrc%2Fbicep%2Fmain.bicep)

## Documentation

Documentation is available at [clemlesne.github.io/blue-agent](https://clemlesne.github.io/blue-agent/).

## [Code of conduct](./CODE_OF_CONDUCT.md)

## [Authors](./AUTHORS.md)
