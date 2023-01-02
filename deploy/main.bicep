// param username string
// @secure()
// param password string
param location string = resourceGroup().location

resource virtualWan 'Microsoft.Network/virtualWans@2022-07-01' = {
  name: 'vwan-hub'
  location: location
  properties: {
    type: 'Standard'
    disableVpnEncryption: false
    allowBranchToBranchTraffic: false
  }
}

resource virtualHub 'Microsoft.Network/virtualHubs@2021-08-01' = {
  name: 'vwan-virtualhub'
  location: location
  properties: {
    addressPrefix: '10.0.0.0/23'
    virtualWan: {
      id: virtualWan.id
    }
  }
}

// module infrastructure 'infrastructure/deploy.bicep' = {
//   name: 'infra-deployment'
//   params: {
//     username: username
//     password: password
//     location: location
//   }
// }

module firewall 'firewall/deploy.bicep' = {
  name: 'firewall-resources-deployment'
  params: {
    location: location
    parentVirtualHubName: virtualHub.name
  }
}

output firewallPrivateIp string = firewall.outputs.firewallPrivateIp
// output bastionName string = infrastructure.outputs.bastionName
// output virtualMachineResourceId string = infrastructure.outputs.virtualMachineResourceId
