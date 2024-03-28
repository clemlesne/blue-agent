param autoscalingMaxReplicas int
param autoscalingMinReplicas int
param extraEnv array
param imageFlavor string
param imageName string
param imageRegistry string
param imageVersion string
param instance string = deployment().name
param location string = resourceGroup().location
param pipelinesCapabilities array
param pipelinesOrganizationURL string
@secure()
param pipelinesPersonalAccessToken string
param pipelinesPoolName string
param pipelinesTimeout int
param resourcesCpu int
param resourcesMemory string
param tags object

var prefix = instance

var pipelinesCapabilitiesEnhanced = union(
  pipelinesCapabilities,
  [
    'flavor_${imageFlavor}'
  ]
)

var pipelinesCapabilitiesEnhancedDict = [for capability in pipelinesCapabilitiesEnhanced: {
  name: capability
  value: ''
}]

var extraEnvDict = [for env in extraEnv: {
  name: env.name
  value: env.value
}]

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: prefix
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource acaEnv 'Microsoft.App/managedEnvironments@2023-11-02-preview' = {
  name: prefix
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        // Consumption workload profile name must be 'Consumption'
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

resource job 'Microsoft.App/jobs@2023-11-02-preview' = {
  name: prefix
  location: location
  tags: tags
  properties: {
    environmentId: acaEnv.id
    configuration: {
      eventTriggerConfig: {
        parallelism: 1  // Only one pod at a time
        scale: {
          maxExecutions: autoscalingMaxReplicas
          minExecutions: autoscalingMinReplicas
          pollingInterval: 15
          rules: [
            {
              name: 'azure-pipelines'
              type: 'azure-pipelines'
              metadata: {
                poolName: pipelinesPoolName
                // Using "demands" instead of "parent" behavior, because we cannot spinup a pod with a no-restart policy on Container Apps. Agents will be triggered based on those pre-defined demands only.
                demands: join(pipelinesCapabilitiesEnhanced, ',')
              }
              auth: [
                {
                  secretRef: 'organization-url'
                  triggerParameter: 'organizationURL'
                }
                {
                  secretRef: 'personal-access-token'
                  triggerParameter: 'personalAccessToken'
                }
              ]
            }
          ]
        }
      }
      triggerType: 'Event'
      replicaTimeout: pipelinesTimeout
      replicaRetryLimit: 0  // Do not retry
      secrets: [
        {
          name: 'personal-access-token'
          value: pipelinesPersonalAccessToken
        }
        {
          name: 'organization-url'
          value: pipelinesOrganizationURL
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${imageRegistry}/${imageName}:${imageFlavor}-${imageVersion}'
          name: 'azp-agent'
          env: union([
            {
              name: 'AGENT_DIAGLOGPATH'
              value: '/app-root/azp-logs'
            }
            {
              name: 'VSO_AGENT_IGNORE'
              value: 'AZP_TOKEN'
            }
            {
              name: 'AGENT_ALLOW_RUNASROOT'
              value: '1'
            }
            {
              name: 'AZP_URL'
              secretRef: 'organization-url'
            }
            {
              name: 'AZP_POOL'
              value: pipelinesPoolName
            }
            {
              name: 'AZP_TOKEN'
              secretRef: 'personal-access-token'
            }
            {
              name: 'flavor_${imageFlavor}'
              value: ''
            }
          ], pipelinesCapabilitiesEnhancedDict, extraEnvDict)
          resources: {
            cpu: resourcesCpu
            memory: resourcesMemory
          }
          volumeMounts: [
            {
              volumeName: 'azp-logs'
              mountPath: '/app-root/azp-logs'
            }
            {
              volumeName: 'azp-work'
              mountPath: '/app-root/azp-work'
            }
            {
              volumeName: 'local-tmp'
              mountPath: '/app-root/.local/tmp'
            }
          ]
        }
      ]
      volumes: [
        {
          name: 'azp-logs'
          storageType: 'EmptyDir'
        }
        {
          name: 'azp-work'
          storageType: 'EmptyDir'
        }
        {
          name: 'local-tmp'
          storageType: 'EmptyDir'
        }
      ]
    }
  }
}
