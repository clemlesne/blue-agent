# Security Policy

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
| `ghcr.io/clemlesne/azure-pipelines-agent:win-ltsc2019-main` | ✅                            |
| `ghcr.io/clemlesne/azure-pipelines-agent:win-ltsc2022-main` | ✅                            |

## Reporting a vulnerability

If you think you have found a vulnerability, please do not open an issue on GitHub. Instead, please send an email to [Clémence Lesné](mailto:clemence@lesne.pro).

## Chain of trust

Both the containers and the Helm chart are signed:

- Containers are signed with Cosign, public keys are available at [`cosign.pub`](cosign.pub) at the root of the repository.
- Helm chart is signed with a GPG key. [The public key is available on Keybase at the following address.](https://keybase.io/clemlesne/pgp_keys.asc)

## Reliability notes

Systems are built every days. Each image is accompanied by a SBOM (Software Bill of Materials) which allows to verify that the installed packages are those expected. This speed has the advantage of minimizing exposure to security flaws, which will then be corrected on the build environments in 24 hours.

Nevertheless it can happen that a package provider (e.g. Debian, Canonical, Red Hat) deploys a system update that introduces a bug. This is difficult to predict.

Each image is pushed with a unique tag, which corresponds to the date of the last update (example: `bullseye-20230313` for a build on March 13, 2023). It is therefore possible to fix the download of a version by modifying the `image.version` property to `20230313`.
