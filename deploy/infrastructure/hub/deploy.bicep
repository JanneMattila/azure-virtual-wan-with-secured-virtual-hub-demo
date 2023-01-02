param name string
param username string
@secure()
param password string
param gatewaySubnetRouteTableId string
param location string

var bastionName = 'bas-management'

resource virtualWan 'Microsoft.Network/virtualWans@2022-07-01' = {
  name: 'vwan-hub'
  location: location
  properties: any({
    type: 'Standard'
    disableVpnEncryption: false
    allowBranchToBranchTraffic: false
    allowVnetToVnetTraffic: false
    office365LocalBreakoutCategory: 'Optimize'
  })
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

resource virtualHubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2022-07-01' = {
  name: 'rt-hub'
  parent: virtualHub
  properties: {
    routes: [
      {
        name: 'Workload-SNToFirewall'
        destinationType: 'CIDR'
        destinations: [
          '10.0.1.0/24'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.id
      }
      {
        name: 'InternetToFirewall'
        destinationType: 'CIDR'
        destinations: [
          '0.0.0.0/0'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.id
      }
    ]
    labels: [
      'VNet'
    ]
  }
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

var managementSubnetId = virtualNetwork.properties.subnets[1].id
var bastionSubnetId = virtualNetwork.properties.subnets[2].id

module vpn 'vpn.bicep' = {
  name: 'vpn-deployment'
  params: {
    name: 'vgw-vpn'
    location: location
    subnetId: gatewaySubnetId
  }
}

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
output gatewaySubnetId string = gatewaySubnetId
output firewallSubnetId string = firewallSubnetId
output managementSubnetId string = managementSubnetId
output bastionSubnetId string = bastionSubnetId
output virtualMachineResourceId string = jumpbox.outputs.virtualMachineResourceId
