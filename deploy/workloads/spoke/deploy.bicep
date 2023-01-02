param parentVirtualHubName string
param virtualHubRouteTableId string
param spokeName string
param vnetAddressSpace string
param subnetAddressSpace string
param location string = resourceGroup().location

var vnetName = 'vnet-${spokeName}'

resource parentVirtualHub 'Microsoft.Network/virtualHubs@2021-08-01' existing = {
  name: parentVirtualHubName
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-${spokeName}-front'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allowAllRule'
        properties: {
          description: 'Allow all traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  tags: {
    'azfw-mapping': spokeName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: 'snet-front'
        properties: {
          addressPrefix: subnetAddressSpace
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          delegations: [
            {
              name: 'ACIDelegation'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

module aci 'container-instances.bicep' = {
  name: '${spokeName}-aci-deployment'
  params: {
    name: 'ci-${spokeName}'
    location: location
    subnetId: virtualNetwork.properties.subnets[0].id
  }
}

resource spokeToVirtualHubNetworkConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-07-01' = {
  parent: parentVirtualHub
  name: 'hub-${spokeName}'
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
