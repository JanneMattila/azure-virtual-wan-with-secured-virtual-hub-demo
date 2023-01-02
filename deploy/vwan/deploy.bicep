param location string = resourceGroup().location
param virtualHubName string

resource virtualWan 'Microsoft.Network/virtualWans@2022-07-01' = {
  name: 'vwan-hub'
  location: location
  properties: {
    type: 'Standard'
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
  }
}

resource virtualHub 'Microsoft.Network/virtualHubs@2021-08-01' = {
  name: virtualHubName
  location: location
  properties: {
    addressPrefix: '10.0.0.0/23'
    virtualWan: {
      id: virtualWan.id
    }
  }
}

module vpn 'vpn.bicep' = {
  name: 'vpn-deployment'
  params: {
    name: 'vgw-vpn'
    location: location
    parentVirtualWanName: virtualWan.name
    parentVirtualHubName: virtualHub.name
  }
}

output virtualWan object = virtualWan
output virtualHub object = virtualHub
output virtualHubName string = virtualHub.name
