---
title: Build ASP.NET applications
---

{{< callout type="info" >}}
.NET Framework is not pre-installed anymore in the agents since `v7.0.0`. You need to install it yourself, with the `UseDotNet@2` or by script. The reason is, to achieve maximum reproducibility, choose the specific version you want to use, and update it through Git.
{{< /callout >}}

Specify the specific version you requires for your build. Install the framework with [UseDotNet@2](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/use-dotnet-v2?view=azure-pipelines):

```yaml
# azure-pipelines.yaml
steps:
  - task: UseDotNet@2
    inputs:
      packageType: sdk
      version: 8.0.0
```

Same way, if you want to use multiple versions of the framework, re-execute the task with the new version. Installations are cached locally and for a single run.
