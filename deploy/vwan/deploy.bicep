param location string = resourceGroup().location
param virtualHubName string

resource virtualWan 'Microsoft.Network/virtualWans@2023-04-01' = {
  name: 'vwan-main'
  location: location
  properties: {
    type: 'Standard'
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
  }
}

resource virtualHub 'Microsoft.Network/virtualHubs@2023-04-01' = {
  name: virtualHubName
  location: location
  properties: {
    addressPrefix: '10.0.0.0/23'
    virtualWan: {
      id: virtualWan.id
    }
  }
}

module expressRoute 'expressroute.bicep' = {
  name: 'er-deployment'
  params: {
    name: 'ergw-${location}'
    location: location
    parentVirtualHubName: virtualHub.name
  }
}

output virtualWan object = virtualWan
output virtualHub object = virtualHub
output virtualHubName string = virtualHub.name
