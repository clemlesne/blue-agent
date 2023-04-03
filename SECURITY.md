# Security Policy

## Chain of trust

The Helm chart is signed with a GPG key. [The public key is available on Keybase at the following address.](https://keybase.io/clemlesne/pgp_keys.asc)

## Reliability notes

Systems are built every days. Each image is accompanied by a SBOM (Software Bill of Materials) which allows to verify that the installed packages are those expected. This speed has the advantage of minimizing exposure to security flaws, which will then be corrected on the build environments in 24 hours. To do this, by default, Kubernetes downloads the image at each pod deployment.

Nevertheless:

- These downloads may incur network costs.
- It can happen that a package provider (e.g. Debian, Canonical, Red Hat) deploys a system update that introduces a bug. This is difficult to predict.

So it is possible to change the `image.pullPolicy` property to `IfNotPresent`, but these updates will not be downloaded automatically. Each image is pushed with a unique tag, which corresponds to the date of the last update (example: `bullseye-20230313` for a build on March 13, 2023). It is therefore possible to fix the download of a version by modifying the `image.version` property to `20230313`.

## Reporting a Vulnerability

If you think you have found a vulnerability, please do not open an issue on GitHub. Instead, please send an email to [Clémence Lesné](mailto:clemence@lesne.pro).

## Support

If you need help or found a bug, please feel free to open an issue on the [clemlesne/azure-pipelines-agent](https://github.com/clemlesne/azure-pipelines-agent) GitHub project.
