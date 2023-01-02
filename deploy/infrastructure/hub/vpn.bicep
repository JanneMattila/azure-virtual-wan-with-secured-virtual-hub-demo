param parentVirtualWanName string
param parentVirtualHubName string
param name string
param location string

resource parentVirtualWan 'Microsoft.Network/virtualWans@2022-07-01' existing = {
  name: parentVirtualWanName
}

resource parentVirtualHub 'Microsoft.Network/virtualHubs@2021-08-01' existing = {
  name: parentVirtualHubName
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'pip-vpn'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnSite 'Microsoft.Network/vpnSites@2021-03-01' = {
  name: 'vst-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
      ]
    }
    // Other properties to evaluate:
    // bgpProperties: {
    //   asn: vpnSiteBgpAsn
    //   bgpPeeringAddress: vpnSiteBgpPeeringAddress
    //   peerWeight: 0
    // }
    deviceProperties: {
      linkSpeedInMbps: 10
    }
    ipAddress: publicIPAddress.properties.ipAddress
    virtualWan: {
      id: parentVirtualWan.id
    }
  }
}

resource vpnGateway 'Microsoft.Network/vpnGateways@2021-03-01' = {
  name: name
  location: location
  properties: {
    connections: [
      {
        name: 'vcn-hub'
        properties: {
          connectionBandwidth: 10
          // Other properties to evaluate:
          // enableBgp: true
          remoteVpnSite: {
            id: vpnSite.id
          }
        }
      }
    ]
    virtualHub: {
      id: parentVirtualHub.id
    }
    // Other properties to evaluate:
    // bgpSettings: {
    //   asn: 65515
    // }
  }
}

output vpnResourceId string = vpnGateway.id
