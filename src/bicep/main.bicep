@description('Maximum number of simultaneous jobs the agent can run')
@minValue(1)
param autoscalingMaxReplicas int = 100
@description('Minimum number of replicas the agent should have')
@minValue(0)
param autoscalingMinReplicas int = 0
@description('Extra environment variables to pass to the agent')
param extraEnv array = []
@description('Flavor of the container image, represents the Linux distribution')
@allowed([
  'bookworm'
  'bullseye'
  'focal'
  'jammy'
  'ubi8'
  'ubi9'
])
param imageFlavor string = 'bookworm'
@description('Name of the container image')
param imageName string = 'clemlesne/azure-pipelines-agent'
@description('Registry of the container image')
@allowed([
  'docker.io'
  'ghcr.io'
])
param imageRegistry string = 'ghcr.io'
@description('Version of the container image, it is recommended to use a specific version like "1.0.0" instead of "latest"')
param imageVersion string = 'main'
@description('Name of the instance, will be used to build the name of the resources')
param instance string = deployment().name
@description('Location of resources')
param location string = 'westeurope'
@description('Capabilities of the agent')
param pipelinesCapabilities array = ['arch_x64']
@description('URL of the Azure DevOps organization')
param pipelinesOrganizationURL string
@description('Personal access token allowing the agent to connect to the Azure DevOps organization')
@secure()
param pipelinesPersonalAccessToken string
@description('Name of the Azure Pipelines self-hosted pool the agent should be added to')
param pipelinesPoolName string
@description('Timeout in seconds for the agent to run a job before it is automatically terminated')
@minValue(1800)
param pipelinesTimeout int = 3600
@description('Number of CPU cores allocated to the agent')
param resourcesCpu int = 2
@description('Amount of memory allocated to the agent')
param resourcesMemory string = '4Gi'

targetScope = 'subscription'

var prefix = 'apa-${instance}'

var tags = {
  application: 'azure-pipelines-agent'
  instance: instance
  managed_by: 'Bicep'
  sources: 'https://github.com/clemlesne/azure-pipelines-agent'
  version: imageVersion
}

resource sub 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: prefix
  tags: tags
}

module agent 'agent.bicep' = {
  name: prefix
  scope: sub
  params: {
    autoscalingMaxReplicas: autoscalingMaxReplicas
    autoscalingMinReplicas: autoscalingMinReplicas
    extraEnv: extraEnv
    imageFlavor: imageFlavor
    imageName: imageName
    imageRegistry: imageRegistry
    imageVersion: imageVersion
    location: location
    pipelinesCapabilities: pipelinesCapabilities
    pipelinesOrganizationURL: pipelinesOrganizationURL
    pipelinesPersonalAccessToken: pipelinesPersonalAccessToken
    pipelinesPoolName: pipelinesPoolName
    pipelinesTimeout: pipelinesTimeout
    resourcesCpu: resourcesCpu
    resourcesMemory: resourcesMemory
    tags: tags
  }
}
