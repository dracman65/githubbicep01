// Parameters \\
param location string
param tags object

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'ghvnetnet01'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/20'
      ]
    }
    subnets: [
      {
        name: 'ghsubnet01'
        properties: {
          addressPrefix: '10.10.0.0/24'
        }
      }
    ]
  }
}

output vnetid string = virtualNetwork.id
output subnetid string = virtualNetwork.properties.subnets[0].id
