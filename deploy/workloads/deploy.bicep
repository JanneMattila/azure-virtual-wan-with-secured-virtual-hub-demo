param parentVirtualHubName string
param virtualHubRouteTableId string
param location string
param username string
@secure()
param password string

var spokes = [
  {
    name: 'spoke001'
    vnetAddressSpace: '10.1.0.0/22'
    subnetAddressSpace: '10.1.0.0/24'
  }
  {
    name: 'spoke002'
    vnetAddressSpace: '10.2.0.0/22'
    subnetAddressSpace: '10.2.0.0/24'
  }
  {
    name: 'spoke003'
    vnetAddressSpace: '10.3.0.0/22'
    subnetAddressSpace: '10.3.0.0/24'
  }
]

module hub 'management/deploy.bicep' = {
  name: 'management-deployment'
  params: {
    parentVirtualHubName: parentVirtualHubName
    virtualHubRouteTableId: virtualHubRouteTableId
    username: username
    password: password
    location: location
  }
}

module spokeDeployments 'spoke/deploy.bicep' = [for (spoke, i) in spokes: {
  name: '${spoke.name}-deployment'
  params: {
    parentVirtualHubName: parentVirtualHubName
    virtualHubRouteTableId: virtualHubRouteTableId
    spokeName: spoke.name
    location: location
    vnetAddressSpace: spoke.vnetAddressSpace
    subnetAddressSpace: spoke.subnetAddressSpace
  }
}]

output bastionName string = hub.outputs.bastionName
output virtualMachineResourceId string = hub.outputs.virtualMachineResourceId
