// Bicep template for Data Collection Rule infrastructure
param DCR_NAME string
param location string
param workspaceName string
param dataCollectionEndpointName string
param customTableName string

// Create Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Create Custom Table in Log Analytics Workspace
resource customTable 'Microsoft.OperationalInsights/workspaces/tables@2023-09-01' = {
  parent: workspace
  name: '${customTableName}Data_CL'
  properties: {
    plan: 'Analytics'
    schema: {
      name: '${customTableName}Data_CL'
      columns: [
        {
          name: 'TimeGenerated'
          type: 'dateTime'
        }
        {
          name: 'Message'
          type: 'string'
        }
        {
          name: 'Severity'
          type: 'string'
        }
      ]
    }
    retentionInDays: 30
  }
}

// Create Data Collection Endpoint
resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: dataCollectionEndpointName
  location: location
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

// Create Data Collection Rule
resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: DCR_NAME
  location: location
  dependsOn: [
    customTable
  ]
  properties: {
    dataCollectionEndpointId: dataCollectionEndpoint.id
    streamDeclarations: {
      'Custom-${customTableName}Data_CL': {
        columns: [
          {
            name: 'TimeGenerated'
            type: 'datetime'
          }
          {
            name: 'Message'
            type: 'string'
          }
          {
            name: 'Severity'
            type: 'string'
          }
        ]
      }
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspace.id
          name: 'workspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Custom-${customTableName}Data_CL'
        ]
        destinations: [
          'workspace'
        ]
        transformKql: 'source'
        outputStream: 'Custom-${customTableName}Data_CL'
      }
    ]
  }
}

// Outputs
output workspaceId string = workspace.id
output dataCollectionEndpointUrl string = dataCollectionEndpoint.properties.logsIngestion.endpoint
output dataCollectionRuleId string = dcr.id
output dataCollectionRuleImmutableId string = dcr.properties.immutableId
output customTableName string = customTable.name
