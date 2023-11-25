---
title: Build ASP.NET applications
---

It was chosen arbitrarily to install the LTS non SDK version of ASNP.NET. Because :

- LTS is better supported by Microsoft than STS
- The non-SDK is lighter when included in a container, knowing that not everyone will use it for building purposes

It is recommended that development teams to hard-code the framework version you want to use, in your pipeline. With this setup, the developer controls its environment, not the platform. If they decide to upgrade, they update the pipeline, if not, not. This is under the responsibility of the developer.

The ASP.NET framework can be installed on the fly with [UseDotNet@2](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/use-dotnet-v2?view=azure-pipelines):

```yaml
# azure-pipelines.yaml
steps:
  - task: UseDotNet@2
    inputs:
      packageType: sdk
      version: 7.0.5
```

Same way, if you want to use multiple versions of the framework, re-execute the task with the new version. Installations are cached locally.
