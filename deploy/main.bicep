param username string
@secure()
param password string
param location string = resourceGroup().location

var virtualHubName = 'vwan-virtualhub'
var virtualHubRouteTableName = 'rt-hub'

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

resource virtualHubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2022-07-01' = {
  name: '${virtualHubName}/${virtualHubRouteTableName}'
  properties: {
    routes: [
      {
        name: 'Workload-SNToFirewall'
        destinationType: 'CIDR'
        destinations: [
          '10.0.1.0/24'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.outputs.firewallId
      }
      {
        name: 'InternetToFirewall'
        destinationType: 'CIDR'
        destinations: [
          '0.0.0.0/0'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.outputs.firewallId
      }
    ]
    labels: [
      'VNet'
    ]
  }
  dependsOn: [
    vwan
  ]
}

module workloads 'workloads/deploy.bicep' = {
  name: 'workloads-deployment'
  params: {
    parentVirtualHubName: virtualHubName
    virtualHubRouteTableId: virtualHubRouteTable.id
    username: username
    password: password
    location: location
  }
}

output firewallPrivateIp string = firewall.outputs.firewallPrivateIp
output bastionName string = workloads.outputs.bastionName
output virtualMachineResourceId string = workloads.outputs.virtualMachineResourceId
