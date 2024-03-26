param parentVirtualHubName string
param name string
param location string

resource parentVirtualHub 'Microsoft.Network/virtualHubs@2023-04-01' existing = {
  name: parentVirtualHubName
}

resource expressRouteGateways 'Microsoft.Network/expressRouteGateways@2023-04-01' = {
  name: name
  location: location

  properties: {
    virtualHub: {
      id: parentVirtualHub.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: 1
        max: 1
      }
    }
  }
}
