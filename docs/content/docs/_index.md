---
linkTitle: Documentation
title: Introduction
---

Blue Agent is self-hosted Azure Pipelines agent in Kubernetes, cheap to run, secure, auto-scaled and easy to deploy.

## Features

- 🏗️ Allow to build containers inside the agent using [BuildKit](https://github.com/moby/buildkit).
- 💪 Performances can be customized depending of the engineering needs, which goes far beyond the Microsoft-hosted agent.
- 📵 Can run air-gapped (no internet access).
- 🔄 Agent register and restart itself.
- 🔧 Packaged with common automation tools ([jq](https://github.com/stedolan/jq), [PowerShell Core](https://github.com/PowerShell/PowerShell), [Python 3](https://python.org), [rsync](https://rsync.samba.org), ...).
- 🖥️ Available with [Azure Linux](https://github.com/microsoft/azurelinux), [Debian](https://debian.org), [Ubuntu](https://ubuntu.com), [Red Hat Enterprise Linux](https://access.redhat.com/products/red-hat-enterprise-linux) and [Windows Server](https://www.microsoft.com/en-us/windows-server)

## Best practices for safety

- 💰 Cheap to run (dynamic provisioning of agents, can scale from 0 to 100+ in few seconds with [KEDA](https://keda.sh)).
- 📦 [SBOM (Software Bill of Materials)](https://en.wikipedia.org/wiki/Software_supply_chain) is packaged with each container image.
- 🔄 System updates are applied every day.
- 🔒 Build authenticity can be cryptographically verified with [Cosign](https://github.com/sigstore/cosign) and GPG.
- 🪶 Slim container images by design.

## Next

{{< cards >}}
{{< card link="getting-started" title="Getting started" icon="check" subtitle="Quick steps to deploy" >}}
{{< card link="security" title="Security" icon="shield-check" subtitle="Chain of trust & reporting a vulnerability" >}}
{{< /cards >}}
