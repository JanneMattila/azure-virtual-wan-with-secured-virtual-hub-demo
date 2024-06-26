param parentVirtualHubName string
param spokeName string
param vnetAddressSpace string
param subnetAddressSpace string
param location string = resourceGroup().location

var vnetName = 'vnet-${spokeName}'

resource parentVirtualHub 'Microsoft.Network/virtualHubs@2023-04-01' existing = {
  name: parentVirtualHubName
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
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

resource spokeToVirtualHubNetworkConnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-04-01' = {
  name: 'vhub-${spokeName}'
  parent: parentVirtualHub
  properties: {
    remoteVirtualNetwork: {
      id: virtualNetwork.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: false
    enableInternetSecurity: true
    routingConfiguration: {}
  }
}
