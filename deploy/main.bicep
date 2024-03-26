param username string
@secure()
param password string
param location string = resourceGroup().location

var virtualHubName = 'vhub-${location}'
// var virtualHubRouteTableName = 'rt-hub'

module vwan 'vwan/deploy.bicep' = {
  name: 'vwan-resources-deployment'
  params: {
    location: location
    virtualHubName: virtualHubName
  }
}

module firewall 'firewall/deploy.bicep' = {
  name: 'firewall-resources-deployment'
  params: {
    location: location
    parentVirtualHubName: virtualHubName
  }
  dependsOn: [
    vwan
  ]
}

resource virtualHubRoutingIntent 'Microsoft.Network/virtualHubs/routingIntent@2023-04-01' = {
  name: '${virtualHubName}/hubRoutingIntent'
  properties: {
    routingPolicies: [
      {
        name: 'Internet'
        destinations: [
          'Internet'
        ]
        nextHop: firewall.outputs.firewallId
      }
      {
        name: 'PrivateTraffic'
        destinations: [
          'PrivateTraffic'
        ]
        nextHop: firewall.outputs.firewallId
      }
    ]
  }
}

// resource virtualHubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2023-04-01' = {
//   name: '${virtualHubName}/${virtualHubRouteTableName}'
//   properties: {
//     routes: []
//     labels: [
//       'VNet'
//     ]
//   }
//   dependsOn: [
//     vwan
//   ]
// }

module workloads 'workloads/deploy.bicep' = {
  name: 'workloads-deployment'
  params: {
    parentVirtualHubName: virtualHubName
    username: username
    password: password
    location: location
  }
  dependsOn: [
    vwan
  ]
}

output firewallPrivateIp string = firewall.outputs.firewallPrivateIp
output bastionName string = workloads.outputs.bastionName
output virtualMachineResourceId string = workloads.outputs.virtualMachineResourceId
