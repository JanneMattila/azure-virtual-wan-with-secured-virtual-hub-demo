param parentVirtualHubName string
param virtualHubRouteTableId string
param username string
@secure()
param password string
param location string

var bastionName = 'bas-management'

resource parentVirtualHub 'Microsoft.Network/virtualHubs@2021-08-01' existing = {
  name: parentVirtualHubName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-management'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/21'
      ]
    }
    subnets: [
      {
        // For intrastructure resources e.g., DCs
        name: 'snet-infra'
        properties: {
          addressPrefix: '10.10.0.0/24'
        }
      }
      {
        // For our demo management subnet to host our VMs
        name: 'snet-management'
        properties: {
          addressPrefix: '10.10.1.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.10.2.0/24'
        }
      }
    ]
  }
}

resource spokeToHubVirtualNetworkConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-07-01' = {
  parent: parentVirtualHub
  name: 'hub-management'
  properties: {
    remoteVirtualNetwork: {
      id: virtualNetwork.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: false
    enableInternetSecurity: true
    routingConfiguration: {
      propagatedRouteTables: {
        labels: [
          'VNet'
        ]
        ids: [
          {
            id: virtualHubRouteTableId
          }
        ]
      }
    }
  }
}

var managementSubnetId = virtualNetwork.properties.subnets[1].id
var bastionSubnetId = virtualNetwork.properties.subnets[2].id

module bastion 'bastion.bicep' = {
  name: 'bastion-deployment'
  params: {
    name: bastionName
    location: location
    subnetId: bastionSubnetId
  }
}

module jumpbox 'jumpbox.bicep' = {
  name: 'jumpbox-deployment'
  params: {
    name: 'jumpbox'
    username: username
    password: password
    location: location
    subnetId: managementSubnetId
  }
}

output id string = virtualNetwork.id
output name string = virtualNetwork.name
output bastionName string = bastionName
output managementSubnetId string = managementSubnetId
output bastionSubnetId string = bastionSubnetId
output virtualMachineResourceId string = jumpbox.outputs.virtualMachineResourceId
