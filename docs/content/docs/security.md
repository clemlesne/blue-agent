---
prev: /advanced-topics
title: Security
weight: 4
---

## Proactive detection of vulnerabilities

At each build, a vulnerability scan is performed on the system. If a vulnerability that can be upgraded is detected, the build is stopped and the image is not pushed to the registry. Vulnerability is reported in [GitHub Security](https://docs.github.com/en/code-security/code-scanning/automatically-scanning-your-code-for-vulnerabilities-and-errors/about-code-scanning). The maintainers are alterted and have access to reports.

Automation is supported by [Snyk](https://snyk.io) and [Semgrep](https://semgrep.dev). Helm chart, configuration files, and containers, are scanned for vulnerabilities and misconfigurations.

Scanned systems:

| `Ref`                                                       | Vulnerability scans with Snyk |
| ----------------------------------------------------------- | ----------------------------- |
| `ghcr.io/clemlesne/azure-pipelines-agent:bookworm-main`     | ✅                            |
| `ghcr.io/clemlesne/azure-pipelines-agent:bullseye-main`     | ✅                            |
| `ghcr.io/clemlesne/azure-pipelines-agent:focal-main`        | ✅                            |
| `ghcr.io/clemlesne/azure-pipelines-agent:jammy-main`        | ✅                            |
| `ghcr.io/clemlesne/azure-pipelines-agent:ubi8-main`         | ✅                            |
| `ghcr.io/clemlesne/azure-pipelines-agent:ubi9-main`         | ✅                            |
| `ghcr.io/clemlesne/azure-pipelines-agent:win-ltsc2019-main` | ✅                            |
| `ghcr.io/clemlesne/azure-pipelines-agent:win-ltsc2022-main` | ✅                            |

## Reporting a vulnerability

If you think you have found a vulnerability, please do not open an issue on GitHub. Instead, please send an email to [Clémence Lesné](mailto:clemence@lesne.pro).

## Chain of trust

Both the containers and the Helm chart are signed:

### Containers

Containers are signed with [Cosign](https://github.com/sigstore/cosign).

Cosign public key is available in [`/cosign.pub`](cosign.pub).

```bash
# Example of verification with Cosign
❯ cosign verify --key cosign.pub ghcr.io/clemlesne/azure-pipelines-agent:bullseye-main
Verification for ghcr.io/clemlesne/azure-pipelines-agent:bullseye-main --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
```

### Helm chart

Helm chart is signed with two methods, [Cosign](https://github.com/sigstore/cosign) and [GPG](https://helm.sh/docs/topics/provenance). Both methods can be used to confirm authenticity of a build.

Keys:

- Cosign public key is available in [`/cosign.pub`](cosign.pub).
- GPG public key is [available on Keybase](https://keybase.io/clemlesne/pgp_keys.asc) and in [`/pubring.gpg`](pubring.gpg).

```bash
# Example of verification with Helm native signature
❯ helm fetch --keyring pubring.gpg --verify clemlesne-azure-pipelines-agent/azure-pipelines-agent --version 5.0.0
Signed by: Clémence Lesné <clemence@lesne.pro>
Using Key With Fingerprint: 417E701DBC66834CA752C920460D072B9C032DFD
Chart Hash Verified: sha256:1c23e22cffc132ce12489480d139b59e97b3cb49ff1599a4ae11fb5c317c1e64
```

```bash
# Example of verification with Cosign
❯ VERSION=5.0.0
❯ wget https://github.com/clemlesne/azure-pipelines-agent/releases/download/azure-pipelines-agent-${VERSION}/azure-pipelines-agent-${VERSION}.tgz.bundle
❯ helm pull clemlesne-azure-pipelines-agent/azure-pipelines-agent --version 5.0.0
❯ cosign verify-blob azure-pipelines-agent-${VERSION}.tgz --bundle azure-pipelines-agent-${VERSION}.tgz.bundle --key cosign.pub
Verified OK
```

## Reliability notes

Systems are built every days. Each image is accompanied by a [SBOM (Software Bill of Materials)](https://en.wikipedia.org/wiki/Software_supply_chain) which allows to verify that the installed packages are those expected. This speed has the advantage of minimizing exposure to security flaws, which will then be corrected on the build environments in 24 hours.

Nevertheless it can happen that a package provider (e.g. Debian, Canonical, Red Hat) deploys a system update that introduces a bug. This is difficult to predict.

Each image is pushed with a unique tag, which corresponds to the date of the last update (example: `bullseye-20230313` for a build on March 13, 2023). It is therefore possible to fix the download of a version by modifying the `image.version` property to `20230313`.
