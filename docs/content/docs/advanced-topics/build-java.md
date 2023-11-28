---
title: Build Java applications
---

Java (JDK and JVM) is not pre-installed into the agents. Specify the specific version you requires for your build. Install the framework with [JavaToolInstaller@0](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/java-tool-installer-v0?view=azure-pipelines), it configures both `PATH` and `JAVA_HOME` environements variables. The JDK file requires to be placed either in Azure Storage or in a local directory:

- Azure Storage (recommended for its audit, replication, and management by API capabilities), downlaod the binary from a central Azure Storage
- Local directory, in the context of a Kubernetes Pod, this directory could be a read-only shared volume mounted in the Pod

First, create an Azure Storage account and a container named `java-temurin`. Then, upload the JDK file to the container. JDK can be downloaded, as example:

- [from Eclipse Temurin](https://adoptium.net/temurin/releases/?package=jdk&os=linux)
- [from Microsoft Build of OpenJDK](https://learn.microsoft.com/en-us/java/openjdk/download) (recommended for its support), based on Eclipse Temurin, but with backported fixes and enhancements not yet been formally backported upstream

Example of an example Azure Storage account named `azure-pipelines-bins` and a container `java-temurin`, with Eclipse Temurin JDK 17 and 21:

```txt
# Azure Storage
/java-temurin (container)
  /jdk
    /21
      OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.1_12.tar
      OpenJDK21U-jdk_x64_linux_hotspot_21.0.1_12.tar
    /17
      OpenJDK17U-jdk_x64_linux_hotspot_17.0.9_9.tar
      [...]
```

Example of the Azure Pipelines YAML file:

```yaml
# azure-pipelines.yaml
steps:
  - task: JavaToolInstaller@0
    inputs:
      azureCommonVirtualFile: jdk/21/OpenJDK21U-jdk_x64_linux_hotspot_21.0.1_12.tar
      azureContainerName: java-temurin
      azureResourceGroupName: AZURE_RESOURCE_GROUP_NAME
      azureResourceManagerEndpoint: AZURE_RESOURCE_MANAGER_SERVICE_CONNECTION_NAME
      azureStorageAccountName: azure-pipelines-bins
      jdkArchitectureOption: x64
      jdkDestinationDirectory: $(agent.toolsDirectory)/jdk/21
      jdkSourceOption: AzureStorage
      versionSpec: 21
```
