---
linkTitle: Documentation
title: Introduction
---

Azure Pipelines Agent is self-hosted agent in Kubernetes, cheap to run, secure, auto-scaled and easy to deploy.

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

## Next

{{< cards >}}
{{< card link="getting-started" title="Getting started" icon="check" subtitle="Quick steps to deploy" >}}
{{< card link="security" title="Security" icon="shield-check" subtitle="Chain of trust & reporting a vulnerability" >}}
{{< /cards >}}
