---
title: Custom root certificate
---

If you need to run the agent with a custom root certificate, you can use the following Helm values. Format is [PEM certificate](https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail) and with [UTF-8](https://en.wikipedia.org/wiki/UTF-8) encoding.

Paths are `/app-root/azp-custom-certs` for Linux-based agents and `C:\app-root\azp-custom-certs` for Windows-based agents.

```yaml
# config-root-ca.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-certs
data:
  root-1.crt: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
  root-2.crt: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
```

```yaml
# values.yaml
extraVolumes:
  - name: custom-certs
    configMap:
      name: custom-certs
extraVolumeMounts:
  - name: custom-certs
    mountPath: /app-root/azp-custom-certs
    readOnly: true
```
