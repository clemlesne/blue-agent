param autoscalingMaxReplicas int
param autoscalingMinReplicas int
param autoscalingPollingInterval int
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

output jobName string = job.name

var prefix = instance

// Capabilities are used to filter the agents that are triggered by the KEDA scaler, allowing developers to select the right agent for their job
var pipelinesCapabilitiesEnhanced = union(
  [
    // OS flavor
    'flavor_${imageFlavor}'
    // Blue Agent version
    'version_${imageVersion}'
  ],
  // Custom capabilities
  pipelinesCapabilities
)

// Convert the capabilities to environment variables dictionary
var pipelinesCapabilitiesEnhancedDict = [
  for capability in pipelinesCapabilitiesEnhanced: {
    name: capability
    value: ''
  }
]

// Convert the custom environment variables k/v to environment variables dictionary
var extraEnvDict = [
  for env in extraEnv: {
    name: env.name
    value: env.value
  }
]

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
  name: substring(prefix, 0, min(32, length(prefix))) // Max length is 32
  location: location
  tags: tags
  properties: {
    environmentId: acaEnv.id
    configuration: {
      eventTriggerConfig: {
        parallelism: 1 // Only one pod at a time
        scale: {
          // Min/max replicas
          maxExecutions: autoscalingMaxReplicas
          minExecutions: autoscalingMinReplicas
          // Rules to scale up/down
          pollingInterval: autoscalingPollingInterval
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
      replicaRetryLimit: 0 // Do not retry
      secrets: [
        // Static token (PAT) allowing the agent to register itself to the pool
        {
          name: 'personal-access-token'
          value: pipelinesPersonalAccessToken
        }
        // Azure DevOps org URL
        // Note: This shouldn't be a secret, but we need to pass it as a secret to be able to consume it in the KEDA trigger
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
          env: union(
            [
              // File logging, should be in a separate volume for performance reasons
              {
                name: 'AGENT_DIAGLOGPATH'
                value: '/app-root/azp-logs'
              }
              // Hide the agent PAT from the logs, for obvious security reasons
              {
                name: 'VSO_AGENT_IGNORE'
                value: 'AZP_TOKEN'
              }
              // Allow agent to run as root (Linux only)
              {
                name: 'AGENT_ALLOW_RUNASROOT'
                value: '1'
              }
              // Azure DevOps org URL
              {
                name: 'AZP_URL'
                secretRef: 'organization-url'
              }
              // Azure DevOps org pool name
              {
                name: 'AZP_POOL'
                value: pipelinesPoolName
              }
              // Azure DevOps PAT allowing the agent to register itself to the pool
              {
                name: 'AZP_TOKEN'
                secretRef: 'personal-access-token'
              }
            ],
            pipelinesCapabilitiesEnhancedDict,
            extraEnvDict
          )
          resources: {
            cpu: resourcesCpu
            memory: resourcesMemory
          }
          volumeMounts: [
            // Separate volume for file logs
            {
              volumeName: 'azp-logs'
              mountPath: '/app-root/azp-logs'
            }
            // Separate volume for job working directory
            {
              volumeName: 'azp-work'
              mountPath: '/app-root/azp-work'
            }
            // Separate volume for system temp files (Linux only)
            {
              volumeName: 'local-tmp'
              mountPath: '/app-root/.local/tmp'
            }
          ]
        }
      ]
      volumes: [
        // Separate volume for file logs
        {
          name: 'azp-logs'
          storageType: 'EmptyDir'
        }
        // Separate volume for job working directory
        {
          name: 'azp-work'
          storageType: 'EmptyDir'
        }
        // Separate volume for system temp files (Linux only)
        {
          name: 'local-tmp'
          storageType: 'EmptyDir'
        }
      ]
    }
  }
}
