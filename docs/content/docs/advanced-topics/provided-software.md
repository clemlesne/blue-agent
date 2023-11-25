---
title: Provided software
---

Softwares are operating system specific. The following table lists the softwares provided by the agent.

#### Linux

- [Azure Pipelines agent](https://github.com/microsoft/azure-pipelines-agent) + [requirements](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)
- [BuildKit](https://github.com/moby/buildkit) + requirements ([dbus-user-session](https://dbus.freedesktop.org), [fuse-overlayfs](https://github.com/containers/fuse-overlayfs), [iptables](https://www.netfilter.org/projects/iptables/index.html), [shadow-utils](https://github.com/shadow-maint/shadow), [uidmap](https://github.com/shadow-maint/shadow))
- Cloud providers CLIs
  - [AWS CLI](https://github.com/aws/aws-cli)
  - [Azure CLI](https://github.com/Azure/azure-cli)
  - [Google Cloud SDK](https://cloud.google.com/sdk)
- Shells
  - [bash](https://www.gnu.org/software/bash) (default)
  - [PowerShell Core](https://github.com/PowerShell/PowerShell)
  - [zsh](https://www.zsh.org)
- Programming languages
  - [ASP.NET Core Runtime](https://github.com/dotnet/aspnetcore)
  - Python ([Python 3.8](https://www.python.org/downloads/release/python-380), [Python 3.9](https://www.python.org/downloads/release/python-390), [Python 3.10](https://www.python.org/downloads/release/python-3100), [Python 3.11](https://www.python.org/downloads/release/python-3110), depending of the system, plus C/Rust build tools for libs non pre-built on the platforms)
- Tools
  - [git](https://github.com/git-for-windows/git)
  - [gzip](https://www.gnu.org/software/gzip)
  - [jq](https://github.com/stedolan/jq)
  - [make](https://www.gnu.org/software/make)
  - [tar](https://www.gnu.org/software/tar)
  - [unzip](https://infozip.sourceforge.net/UnZip.html)
  - [wget](https://www.gnu.org/software/wget)
  - [yq](https://github.com/mikefarah/yq)
  - [zip](https://infozip.sourceforge.net/Zip.html)
  - [zstd](https://github.com/facebook/zstd)

#### Windows

- [Azure Pipelines agent](https://github.com/microsoft/azure-pipelines-agent) + [requirements](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)
- Cloud providers CLIs
  - [AWS CLI](https://github.com/aws/aws-cli)
  - [Azure CLI](https://github.com/Azure/azure-cli)
  - [Google Cloud SDK](https://cloud.google.com/sdk)
- Shells
  - [PowerShell Core](https://github.com/PowerShell/PowerShell) (default)
  - [Windows PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-7.3)
- Programming languages
  - [.NET SDK](https://dotnet.microsoft.com)
  - [Python 3.11](https://www.python.org/downloads/release/python-3110)
  - [Visual Studio Build Tools](https://learn.microsoft.com/en-us/visualstudio/ide/?view=vs-2022) (with `AzureBuildTools`, `VCTools`, `WebBuildTools`, `ManagedDesktopBuildTools`, `OfficeBuildTools` workloads)
- Tools
  - [git](https://github.com/git-for-windows/git)
  - [jq](https://github.com/stedolan/jq)
  - [yq](https://github.com/mikefarah/yq)
  - [zstd](https://github.com/facebook/zstd)
