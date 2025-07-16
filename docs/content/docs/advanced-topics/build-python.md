---
title: Build Python applications
---

Blue Agent provides Python pre-installed across all container flavors. It is strongly recommended to use a fixed version of Python to ensure consistent and reproducible builds across different environments. Both basic setup and uv dependency management approaches are described below, but not limited to these.

## Recommended approach

Recently uv tends to be both faster and more efficient than pip for Python package management, in addition to be simpler to use for developers. It is recommended to use uv for Python dependency management in Blue Agent pipelines.

## Install approaches

### Modern dependency management with uv

For fast and efficient Python package management, consider using [uv](https://github.com/astral-sh/uv) - an extremely fast Python package resolver and installer written in Rust. It is significantly faster than pip and provides excellent dependency resolution capabilities.

```yaml
# azure-pipelines.yaml
steps:
  # Cache uv dependencies for faster builds
  - task: Cache@2
    inputs:
      key: 'uv | "$(Agent.OS)" | uv.lock'
      restoreKeys: |
        uv | "$(Agent.OS)"
      path: $(Pipeline.Workspace)/.uv-cache
    displayName: Cache uv dependencies

  # Install uv
  - script: |
      python3 -m pip install uv
    displayName: Install uv

  # Create virtual environment with uv
  - script: |
      uv venv --python 3.13
      echo "##vso[task.setvariable variable=VIRTUAL_ENV]$(pwd)/.venv"
    displayName: Create virtual environment with uv

  # Activate virtual environment (Linux/macOS)
  - script: |
      echo "##vso[task.prependpath]$(pwd)/.venv/bin"
    displayName: Activate virtual environment (Linux/macOS)
    condition: ne(variables['Agent.OS'], 'Windows_NT')

  # Activate virtual environment (Windows)
  - script: |
      echo "##vso[task.prependpath]$(pwd)/.venv/Scripts"
    displayName: Activate virtual environment (Windows)
    condition: eq(variables['Agent.OS'], 'Windows_NT')

  # Install dependencies with uv
  - script: |
      uv sync --cache-dir $(Pipeline.Workspace)/.uv-cache
    displayName: Install dependencies with uv
```

uv offers several advantages over traditional pip-based workflows:

- **Speed**: uv is 10-100x faster than pip for dependency resolution and installation
- **Deterministic**: Built-in lockfile support ensures reproducible builds
- **Modern**: Supports modern Python packaging standards out of the box
- **Caching**: Intelligent caching reduces redundant downloads and installations

For projects using `pyproject.toml`, uv can automatically handle dependency installation and virtual environment management with a single `uv sync` command.

### Basic setup

For optimal compatibility and reproducibility, use the `UsePythonVersion@0` task to specify the exact Python version rather than relying on the default system Python. This approach ensures your pipeline works consistently across different agent flavors and environments.

```yaml
# azure-pipelines.yaml
steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: "3.12"
      architecture: x64
    displayName: Use Python 3.12
```

For reproducible and reliable dependency management, consider using [pip-tools](https://github.com/jazzband/pip-tools) to pin your dependencies precisely. This approach helps prevent dependency conflicts and ensures consistent builds across different environments.

```yaml
# azure-pipelines.yaml
steps:
  # Fix version for reproducibility
  - task: UsePythonVersion@0
    inputs:
      versionSpec: "3.12"
      architecture: x64
    displayName: Use Python 3.12

  # Cache pip dependencies for faster builds
  - task: Cache@2
    inputs:
      key: 'pip | "$(Agent.OS)" | requirements.txt'
      restoreKeys: |
        pip | "$(Agent.OS)"
      path: $(Pipeline.Workspace)/.pip
    displayName: Cache pip dependencies

  # Install pip-tools for dependency management
  - script: |
      python3 -m pip install pip-tools
    displayName: Install pip-tools

  # Sync dependencies from requirements.txt
  - script: |
      pip-sync --pip-args "--no-deps --cache-dir $(Pipeline.Workspace)/.pip" requirements.txt
    displayName: Install dependencies with pip-tools
```

This approach ensures that your dependencies are installed exactly as specified, without allowing pip to resolve and install additional dependencies that might cause conflicts.

## Available Python versions

Blue Agent provides Python pre-installed with specific versions optimized for each container flavor:

### Linux Flavors

| Flavor        | Python Version | Installation Method |
| ------------- | -------------- | ------------------- |
| `azurelinux3` | 3.12           | Built from source   |
| `bookworm`    | 3.13           | Built from source   |
| `jammy`       | 3.13           | Built from source   |
| `noble`       | 3.13           | Built from source   |
| `ubi8`        | 3.13           | Built from source   |
| `ubi9`        | 3.13           | Built from source   |

### Windows Flavors

| Flavor         | Python Version | Installation Method        |
| -------------- | -------------- | -------------------------- |
| `win-ltsc2022` | 3.13           | Official Windows installer |
| `win-ltsc2025` | 3.13           | Official Windows installer |

### Python Path Configuration

- **Linux**: Python is available as `python`, `python3`, and `python3.x` (where x is the minor version)
- **Windows**: Python is available as `python` and `python3`
- All flavors have pip available as `python -m pip` and `python3 -m pip`
