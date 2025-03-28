// Parameters

param nkvname string
param location string
param enableSoftDelete bool = false
param enableVaultForDeployment bool = true
param enableVaultForTemplateDeployment bool = true
param enableVaultForDiskEncryption bool = true
param softDeleteRetentionInDays int = 7
param kvtags object
param uamiObjectId string

// Key Vault \\

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: nkvname
  location: location
  tags: kvtags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: uamiObjectId // Need to add Group, User, Service Principal to Entra/AD.
        permissions: {
          secrets: ['get', 'list', 'get', 'purge', 'recover', 'restore', 'set']
          keys: ['get', 'list', 'purge', 'delete', 'backup', 'restore', 'decrypt', 'purge', 'rotate']
          certificates: ['get', 'list', 'update', 'create', 'import', 'delete', 'backup', 'restore', 'recover', 'purge']
        }
      }
    ]
    enableSoftDelete: enableSoftDelete
    enabledForDeployment: enableVaultForDeployment
    enabledForTemplateDeployment: enableVaultForTemplateDeployment
    enabledForDiskEncryption: enableVaultForDiskEncryption
    softDeleteRetentionInDays: softDeleteRetentionInDays
  }
}

//  Role Assignment \\

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, uamiObjectId, '00482a5a-887f-4fb3-b363-3b7fe8e74483') // Key Vault Contributor role
  scope: keyVault
  properties: {
    principalId: uamiObjectId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Contributor role
    )
    principalType: 'User'
  }
}

// Output
output outputKvtId string = resourceId('Microsoft.KeyVault/vaults', nkvname)
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
