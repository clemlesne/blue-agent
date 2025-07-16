---
title: Build ASP.NET applications
---

Blue Agent provides ASP.NET Core runtime pre-installed across all container flavors. The project includes ASP.NET Core 8.0 runtime by default, but development teams can install specific SDK versions as needed for their build requirements.

## What's pre-installed

All Blue Agent container images include:

- **ASP.NET Core 8.0 Runtime**: Available across all Linux flavors
- **ASP.NET Core 8.0 SDK**: Available in Windows flavors

The runtime-only approach for Linux containers keeps the image size minimal while providing the necessary components for running ASP.NET applications.

## Recommended approach

It is strongly recommended that development teams specify the exact .NET version they require in their pipeline. This approach ensures:

- **Reproducible builds**: Same environment across all pipeline runs
- **Developer control**: Teams choose when to upgrade, not the platform
- **Consistency**: Predictable behavior across different agent instances

## Install specific SDK versions

For building ASP.NET applications, install the specific SDK version using [UseDotNet@2](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/use-dotnet-v2?view=azure-pipelines):

{{< callout type="info" >}}
The caching example below requires a `packages.lock.json` file. [Enable this by adding `<RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>`](https://devblogs.microsoft.com/dotnet/enable-repeatable-package-restores-using-a-lock-file/) to your project file or run `dotnet restore --use-lock-file`.
{{< /callout >}}

```yaml
# azure-pipelines.yaml
steps:
  # Cache NuGet packages for faster builds
  - task: Cache@2
    inputs:
      key: 'nuget | "$(Agent.OS)" | **/packages.lock.json'
      restoreKeys: |
        nuget | "$(Agent.OS)"
      path: $(Pipeline.Workspace)/.nuget/packages
    displayName: Cache NuGet packages

  # Install specific .NET SDK version
  - task: UseDotNet@2
    inputs:
      packageType: sdk
      version: 8.0.x
    displayName: Install .NET SDK 8.0.x

  # Restore dependencies
  - script: dotnet restore
    displayName: Restore NuGet packages
```

## Multi-targeting scenarios

For projects requiring multiple .NET versions, install each version sequentially:

```yaml
steps:
  - task: UseDotNet@2
    inputs:
      packageType: sdk
      version: 6.0.x
    displayName: Install .NET SDK 6.0.x

  - task: UseDotNet@2
    inputs:
      packageType: sdk
      version: 8.0.x
    displayName: Install .NET SDK 8.0.x

  - script: dotnet build --configuration Release --framework net6.0
    displayName: Build for .NET 6.0

  - script: dotnet build --configuration Release --framework net8.0
    displayName: Build for .NET 8.0
```
