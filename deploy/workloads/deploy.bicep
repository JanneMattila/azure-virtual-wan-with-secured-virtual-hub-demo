param parentVirtualHubName string
param location string
param username string
@secure()
param password string

var spokes = [
  {
    name: 'spoke001'
    vnetAddressSpace: '10.1.0.0/22'
    subnetAddressSpace: '10.1.0.0/24'
    location: location
  }
  {
    name: 'spoke002'
    vnetAddressSpace: '10.2.0.0/22'
    subnetAddressSpace: '10.2.0.0/24'
    location: location // 'northeurope'
  }
  {
    name: 'spoke003'
    vnetAddressSpace: '10.3.0.0/22'
    subnetAddressSpace: '10.3.0.0/24'
    location: location // 'francecentral'
  }
]

module hub 'management/deploy.bicep' = {
  name: 'management-deployment'
  params: {
    parentVirtualHubName: parentVirtualHubName
    username: username
    password: password
    location: location
  }
}

module spokeDeployments 'spoke/deploy.bicep' = [
  for (spoke, i) in spokes: {
    name: '${spoke.name}-deployment'
    params: {
      parentVirtualHubName: parentVirtualHubName
      spokeName: spoke.name
      location: spoke.location // Or just location if you want to use the same location as the hub
      vnetAddressSpace: spoke.vnetAddressSpace
      subnetAddressSpace: spoke.subnetAddressSpace
    }
  }
]

output bastionName string = hub.outputs.bastionName
output virtualMachineResourceId string = hub.outputs.virtualMachineResourceId
