---
title: Proxy
---

If you need to use a proxy, you can set the following environment variables. See [this documentation](https://github.com/microsoft/azure-pipelines-agent/blob/master/docs/start/proxyconfig.md) for more details.

```yaml
# values.yaml
extraEnv:
  - name: VSTS_HTTP_PROXY
    value: http://proxy:8080
  - name: VSTS_HTTP_PROXY_USERNAME
    value: username
  - name: VSTS_HTTP_PROXY_PASSWORD
    value: password
```
