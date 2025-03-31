targetScope = 'subscription'

// Parameters \\
param location string
// param tags string
param ghdemorg01 string
param vnetName string
param vnetSubnetName string
param vmName string
param name string
param nkvname string
//param keyvaultname string
param uamiObjectId string

// Variables \\
var baseName = substring(uniqueString(deployment().name), 0, 6)

// Create a short, unique suffix, that will be unique to each resource group
//var uniqueSuffix = substring(uniqueString(deployment().name), 0, 6)
var uniqueSuffix2 = substring(uniqueString(environment().name), 0, 6)

// Functions \\
// Remove hyphens and other non-alphanumeric characters from resource names
func sanitizeResourceName(value string) string => toLower(removeTrailingHyphen(removeColons(removeCommas(removeDots(removeSemicolons(removeUnderscores(removeWhiteSpaces(value))))))))
func removeTrailingHyphen(value string) string => endsWith(value, '-') ? substring(value, 0, length(value)-1) : value
func removeColons(value string) string => replace(value, ':', '')
func removeCommas(value string) string => replace(value, ',', '')
func removeDots(value string) string => replace(value, '.', '')
func removeSemicolons(value string) string => replace(value, ';', '')
func removeUnderscores(value string) string => replace(value, '_', '')
func removeWhiteSpaces(value string) string => replace(value, ' ', '')
func shouldBeShortened(resourceType string) bool => contains(getResourcesTypesToShorten(), resourceType)
func getResourcesTypesToShorten() array => [
  // 'keyVaultname'
  // 'storageAccountname'
  'linuxwindowsvm'
]
func shortenString(value string) string => removeHyphens(sanitizeResourceName(value))
func removeHyphens(value string) string => replace(value, '-', '')

// Resource Groups \\
resource ghtstresgrp01 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: ghdemorg01
  location: location
  tags: rgtags
}

// Resource Groups Tags \\
param rgtags object = {
  Name: 'ResourceGroup'
  EnvironmentName: 'ghdemorg01'
  CostCenter: '10101010'
  Team: 'OCTO IT'
  Deployment: 'Bicep'
  Date: '03-26-25'
}

// Selected Linux VM Module \\
module linuxvm './modules/linuxwinvm/linuxvm.bicep' = {
  scope: ghtstresgrp01
  name: vmName
  params: {
    location: location
    vmPass: 'Password123$'
    vmUserName: 'xadministrator'
    linuxversion: 'Ubuntu-2204-LTS'
    tags: linuxtags
    vnetName: vnetName
    vnetSubnetName: vnetSubnetName
    vmName: vmName
  }
}

// Linux Tags \\
param linuxtags object = {
  Name: 'ResourceGroup'
  EnvironmentName: 'linuxwindowsvm'
  CostCenter: '10101010'
  Team: 'OCTO IT'
  Deployment: 'Bicep'
  Date: '03-26-25'
}

// VNET Module \\
module vnet './modules/linuxwinvm/vnet.bicep' = {
  scope: ghtstresgrp01
  name: 'logAnalyticsWS'
  params: {
    location: location
    tags: vnettags
  }
}

// VNET Tags \\
param vnettags object = {
  Name: 'ghvnettst'
  EnvironmentName: 'vnetghtst01'
  CostCenter: '10101010'
  Team: 'OCTO IT'
  Deployment: 'Bicep'
  Date: '03-26-25'
}

//Storage Account Module \\
module storage './modules/linuxwinvm/storage.bicep' = {
  scope: ghtstresgrp01
  name: 'st${baseName}-deployment'
  params: {
    location: location
    storageName: 'st${name}${uniqueSuffix2}'
    storageSkuName: 'Standard_LRS'
    tags: stgtags
  }
}

// Storage Tags \\
param stgtags object = {
  Name: 'ghvnettst'
  EnvironmentName: 'vnetghtst01'
  CostCenter: '10101010'
  Team: 'OCTO IT'
  Deployment: 'Bicep'
  Date: '03-26-25'
}

// Key Vault \\
module keyVault './modules/linuxwinvm/keyvault.bicep' = {
  scope: ghtstresgrp01
  name: nkvname
  params: {
    nkvname: nkvname
    location: location
    enableSoftDelete: true
    kvtags: kvtags
    uamiObjectId: uamiObjectId
  }
}
// Key Vault Tags \\
param kvtags object = {
  Name: 'ghvnettst'
  EnvironmentName: 'vnetghtst01'
  CostCenter: '10101010'
  Team: 'OCTO IT'
  Deployment: 'Bicep'
  Date: '03-26-25'
}
